@import WebKit;

#import "NYPLAccount.h"
#import "NYPLBook.h"
#import "NYPLBookLocation.h"
#import "NYPLBookRegistry.h"
#import "NYPLJSON.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLNull.h"
#import "NYPLReaderContainerDelegate.h"
#import "NYPLReaderRenderer.h"
#import "NYPLReaderSettings.h"
#import "NYPLReaderTOCElement.h"
#import "NYPLReadium.h"
#import "UIColor+NYPLColorAdditions.h"
#import "NYPLLog.h"
#import "NYPLReaderReadiumView.h"
#import "UIColor+NYPLColorAdditions.h"
#import "NSURL+NYPLURLAdditions.h"
#import "NYPLConfiguration.h"
#import "NYPLAlertController.h"
#import "NYPLRootTabBarController.h"
#import "SimplyE-Swift.h"

@interface NYPLReaderReadiumView ()
  <NYPLReaderRenderer, RDPackageResourceServerDelegate, WKNavigationDelegate>

@property (nonatomic) BOOL postLastRead;
@property (nonatomic) NYPLBook *book;
@property (nonatomic) BOOL bookIsCorrupt;
@property (nonatomic) RDContainer *container;
@property (nonatomic) NYPLReaderContainerDelegate *containerDelegate;
@property (nonatomic) BOOL loaded;
@property (nonatomic) BOOL mediaOverlayIsPlaying;
@property (nonatomic) NSInteger openPageCount;
@property (nonatomic) RDPackage *package;
@property (nonatomic) BOOL pageProgressionIsLTR;
@property (nonatomic) BOOL isPageTurning, canGoLeft, canGoRight;
@property (nonatomic) RDPackageResourceServer *server;
@property (nonatomic) NSArray *TOCElements;
@property (nonatomic) WKWebView *webView;

@property (nonatomic) NSDictionary *bookMapDictionary;
@property (nonatomic) NSUInteger spineItemPageIndex;
@property (nonatomic) NSUInteger spineItemPageCount;
@property (nonatomic) float progressWithinBook; // [0, 1]
@property (nonatomic) NSDictionary *spineItemDetails;

@property (nonatomic) BOOL javaScriptIsRunning;
@property (nonatomic) NSMutableArray *javaScriptHandlerQueue;
@property (nonatomic) NSMutableArray *javaScriptStringQueue;

@property (nonatomic) BOOL performingLongLoad;
@property (nonatomic) double secondsSinceComplete;

@end

static NSString *const renderer = @"readium";

// The web view will be checked this often to see if it is done loading. This check
// is what allows the |rendererDidBeginLongLoad:| and |rendererDidEndLongLoad:|
// methods to work.
static float readyStateCheckIntervalInSeconds = 0.1;

static id argument(NSURL *const URL)
{
  NSString *const s = URL.resourceSpecifier;
  
  NSRange const range = [s rangeOfString:@"/"];
  
  assert(range.location != NSNotFound);
  
  NSData *const data = [[[s substringFromIndex:(range.location + 1)]
                         stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                        dataUsingEncoding:NSUTF8StringEncoding];
  
  return NYPLJSONObjectFromData(data);
}

static void generateTOCElements(NSArray *const navigationElements,
                                NSUInteger const nestingLevel,
                                NSMutableArray *const TOCElements)
{
  for(RDNavigationElement *const navigationElement in navigationElements) {
    NYPLReaderTOCElement *const TOCElement =
      [[NYPLReaderTOCElement alloc]
       initWithOpaqueLocation:((NYPLReaderRendererOpaqueLocation *) navigationElement)
       title:navigationElement.title
       nestingLevel:nestingLevel];
    [TOCElements addObject:TOCElement];
    generateTOCElements(navigationElement.children, nestingLevel + 1, TOCElements);
  }
}

// The idea for this was taken from here:
// http://stackoverflow.com/a/34679880
//
// We must use this approach to disable text selection beause "user-select: none;"
// breaks bookmarking in Readium due to a bug in WebKit:
// https://bugs.chromium.org/p/chromium/issues/detail?id=263813

static void removeCalloutBarFromSuperviewStartingFromView(UIView *const view)
{
  // This seems to be the only reliable way of finding the correct view.
  if([view isMemberOfClass:[UIView class]] && CGRectIsEmpty(view.frame))
  {
    [view removeFromSuperview];
  } else {
    for(UIView *const subview in [view subviews]) {
      removeCalloutBarFromSuperviewStartingFromView(subview);
    }
  }
}

@implementation NYPLReaderReadiumView

- (instancetype)initWithFrame:(CGRect const)frame
                         book:(NYPLBook *const)book
                     delegate:(id<NYPLReaderRendererDelegate> const)delegate
{
  self = [super initWithFrame:frame];
  if(!self) return nil;
  
  if(!book) {
    NYPLLOG(@"Failed to initialize due to nil book.");
    return nil;
  }
  self.postLastRead = NO;
  
  self.book = book;
  self.containerDelegate = [[NYPLReaderContainerDelegate alloc] init];
  
  self.delegate = delegate;
  
  @try {
    self.container = [[RDContainer alloc]
                      initWithDelegate:self.containerDelegate
                      path:[[[NYPLMyBooksDownloadCenter sharedDownloadCenter]
                             fileURLForBookIndentifier:book.identifier]
                            path]];
  } @catch (...) {
    self.bookIsCorrupt = YES;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      [self.delegate renderer:self didEncounterCorruptionForBook:book];
    }];
  }
  
  self.package = self.container.firstPackage;
  self.server = [[RDPackageResourceServer alloc]
                 initWithDelegate:self
                 package:self.package
                 specialPayloadAnnotationsCSS:nil
                 specialPayloadMathJaxJS:nil];
  
  self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 60, self.bounds.size.width, self.bounds.size.height - 100)];
  self.webView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                   UIViewAutoresizingFlexibleWidth);
  self.webView.navigationDelegate = self;
  self.webView.scrollView.bounces = NO;
  self.webView.alpha = 0.0;
  [self addSubview:self.webView];
  
  self.webView.isAccessibilityElement = YES;
  [self.webView loadRequest:
   [NSURLRequest requestWithURL:
    [NSURL URLWithString:
     [NSString stringWithFormat:
      @"http://127.0.0.1:%d/simplified-readium/reader.html",
      self.server.port]]]];
  
  // Disable text selection.
  removeCalloutBarFromSuperviewStartingFromView(self.webView);
  
  [self addObservers];
  
  self.backgroundColor = [NYPLReaderSettings sharedSettings].backgroundColor;
  
  [NYPLReaderSettings sharedSettings].currentReaderReadiumView = self;
  
  self.javaScriptIsRunning = NO;
  self.javaScriptHandlerQueue = [NSMutableArray array];
  self.javaScriptStringQueue = [NSMutableArray array];
  
  return self;
}

- (void)addObservers
{
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(applyCurrentFlowIndependentSettings)
   name:NYPLReaderSettingsColorSchemeDidChangeNotification
   object:nil];
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(applyCurrentFlowIndependentSettings)
   name:NYPLReaderSettingsFontFaceDidChangeNotification
   object:nil];
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(applyCurrentFlowDependentSettings)
   name:NYPLReaderSettingsFontSizeDidChangeNotification
   object:nil];
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(applyCurrentFlowDependentSettings)
   name:NYPLReaderSettingsMediaClickOverlayAlwaysEnableDidChangeNotification
   object:nil];
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(applyMediaOverlayPlaybackToggle)
   name:NYPLReaderSettingsMediaOverlayPlaybackToggleDidChangeNotification
   object:nil];
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(willResignActive)
   name:UIApplicationWillResignActiveNotification
   object:nil];
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(didBecomeActive)
   name:UIApplicationDidBecomeActiveNotification
   object:nil];
}

- (void)applyCurrentFlowDependentSettings
{
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    
    NSString *const javaScript = [NSString stringWithFormat:
                                  @"ReadiumSDK.reader.updateSettings(%@)",
                                  [[NSString alloc]
                                   initWithData:NYPLJSONDataFromObject([[NYPLReaderSettings sharedSettings]
                                                                        readiumSettingsRepresentation])
                                   encoding:NSUTF8StringEncoding]];
    [self sequentiallyEvaluateJavaScript:javaScript];
    [self sequentiallyEvaluateJavaScript:@"simplified.settingsDidChange();"];
  }];
}

- (void)applyCurrentFlowIndependentSettings
{
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    NSArray *const styles = [[NYPLReaderSettings sharedSettings] readiumStylesRepresentation];
    
    NSString *const stylesString = [[NSString alloc]
                                    initWithData:NYPLJSONDataFromObject(styles)
                                    encoding:NSUTF8StringEncoding];
    
    NSString *const javaScript =
    [NSString stringWithFormat:
     @"ReadiumSDK.reader.setBookStyles(%@);"
     @"document.body.style.backgroundColor = \"%@\";",
     stylesString,
     [[NYPLReaderSettings sharedSettings].backgroundColor javascriptHexString]];
    [self sequentiallyEvaluateJavaScript:javaScript];
    
    
    NSString *javascriptToChangeHighlightColour = [NSString stringWithFormat:@" \
                                                   window.nsRdHighlightColor = '%@'; \
                                                   var reader = ReadiumSDK.reader; \
                                                   var stylesheetText = function(color){return \".-epub-media-overlay-active {background-color: \" + color + \" !important;}\"}; \
                                                   \
                                                   _.each(reader.getLoadedSpineItems(), function(spineItem){ \
                                                   var el = reader.getElement(spineItem, '#ns-rd-custom-styles'); \
                                                   if (el) { \
                                                   el[0].textContent = stylesheetText(window.nsRdHighlightColor); \
                                                   } \
                                                   }); \
                                                   ",  [NYPLReaderSettings sharedSettings].backgroundMediaOverlayHighlightColor.javascriptHexString];
    
    [self sequentiallyEvaluateJavaScript:javascriptToChangeHighlightColour];
    
    self.backgroundColor = [NYPLReaderSettings sharedSettings].backgroundColor;
    self.webView.backgroundColor = [NYPLReaderSettings sharedSettings].backgroundColor;
    [self sequentiallyEvaluateJavaScript:@"simplified.settingsDidChange();"];
  }];
}

- (void) applyMediaOverlayPlaybackToggle
{
  __weak NYPLReaderReadiumView *const weakSelf = self;
  
  [self
   sequentiallyEvaluateJavaScript:@"ReadiumSDK.reader.isPlayingMediaOverlay()"
   withCompletionHandler:^(id _Nullable result, __unused NSError *_Nullable error) {
     BOOL const isPlaying = [result boolValue];
     [weakSelf
      sequentiallyEvaluateJavaScript:@"ReadiumSDK.reader.isMediaOverlayAvailable()"
      withCompletionHandler:^(id _Nullable result, __unused NSError *_Nullable error) {
        BOOL const isAvailable = [result boolValue];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          NSString *javaScript;
          if (!isPlaying && isAvailable) {
            javaScript = [NSString stringWithFormat: @"ReadiumSDK.reader.playMediaOverlay()"];
            
            if(UIAccessibilityIsVoiceOverRunning())
            {
              weakSelf.webView.accessibilityElementsHidden = YES;
            }
          }
          else {
            javaScript = [NSString stringWithFormat: @"ReadiumSDK.reader.pauseMediaOverlay()"];
            
            if(UIAccessibilityIsVoiceOverRunning())
            {
              weakSelf.webView.accessibilityElementsHidden = NO;
            }
          }
          [weakSelf sequentiallyEvaluateJavaScript:javaScript];
        }];
      }];
   }];
}

- (void)willResignActive
{
  [self.server stopHTTPServer];
}

- (void)didBecomeActive
{
  [self.server startHTTPServer];
}

- (void) openPageLeft {
  if (!self.canGoLeft)
    return;
  self.isPageTurning = YES;
  self.webView.alpha = 0.0;
  [self sequentiallyEvaluateJavaScript:@"ReadiumSDK.reader.openPageLeft()"];
}

- (void) openPageRight {
  if (!self.canGoRight)
    return;
  self.isPageTurning = YES;
  self.webView.alpha = 0.0;
  [self sequentiallyEvaluateJavaScript:@"ReadiumSDK.reader.openPageRight()"];
}

- (BOOL) touchIntersectsLink:(UITouch *)touch
{
  // Adapted from http://stackoverflow.com/questions/7216356/iphone-tapgesture-on-uiwebview-conflicts-with-the-link-clicking
  
  __block BOOL retVal = NO;
  
  //Check if a link was clicked
  NSString *js = @"simplified.getSemicolonSeparatedLinkRects()";
  
  dispatch_semaphore_t sephamore = dispatch_semaphore_create(0);
  
  __weak NYPLReaderReadiumView *const weakSelf = self;
  
  [self
   sequentiallyEvaluateJavaScript:js
   withCompletionHandler:^(id _Nullable result, __unused NSError * _Nullable error) {
     NSArray *linkArray = [result componentsSeparatedByString:@";"];
     CGPoint touchPoint = [touch locationInView:weakSelf.webView];
     for ( NSString *linkRectStr in linkArray ) {
       CGRect rect = CGRectFromString(linkRectStr);
       if ( CGRectContainsPoint( rect, touchPoint ) ) {
         retVal = YES;
         break;
       }
     }
     dispatch_semaphore_signal(sephamore);
   }];
  
  while(dispatch_semaphore_wait(sephamore, DISPATCH_TIME_NOW)) {
    [[NSRunLoop currentRunLoop]
     runMode:NSDefaultRunLoopMode
     beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  }
  
  return retVal;
}

#pragma mark NSObject

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark RDPackageResourceServerDelegate

- (void)
packageResourceServer:(__attribute__((unused)) RDPackageResourceServer *)packageResourceServer
executeJavaScript:(NSString *const)javaScript
{
  [self sequentiallyEvaluateJavaScript:javaScript];
}

#pragma mark WKNavigationDelegate

- (void)webView:(__unused WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
  if(self.bookIsCorrupt) {
    decisionHandler(WKNavigationActionPolicyCancel);
    return;
  }
  
  NSURLRequest *const request = navigationAction.request;
  
  if([request.URL.scheme isEqualToString:@"simplified"]) {
//    NSArray *const components = [request.URL.resourceSpecifier componentsSeparatedByString:@"/"];
//    NSString *const function = components[0];
    NYPLLOG(@"Ignoring unknown simplified function.");
    decisionHandler(WKNavigationActionPolicyCancel);
    return;
  }
  
  else if([request.URL.scheme isEqualToString:@"readium"]) {
    NSArray *const components = [request.URL.resourceSpecifier componentsSeparatedByString:@"/"];
    NSString *const function = components[0];
    if([function isEqualToString:@"initialize"]) {
      [self readiumInitialize];
      [self pollReadyState];
    } else if([function isEqualToString:@"pagination-changed"]) {
      [self readiumPaginationChangedWithDictionary:argument(request.URL)];
    } else if([function isEqualToString:@"media-overlay-status-changed"]) {
      NSDictionary *const dict = argument(request.URL);
      self.mediaOverlayIsPlaying = ((NSNumber *) dict[@"isPlaying"]).boolValue;
      [self mediaOverlayStatusChangedWithDictionary:argument(request.URL)];
    } else if([function isEqualToString:@"settings-applied"]) {
      NSLog(@"");
      // Do nothing.
    } else {
      NYPLLOG(@"Ignoring unknown readium function.");
    }
    decisionHandler(WKNavigationActionPolicyCancel);
    return;
  }
  
  else {
    if (request.URL.isNYPLExternal) {
      [[UIApplication sharedApplication] openURL:(NSURL *__nonnull)request.URL];
      decisionHandler(WKNavigationActionPolicyCancel);
      return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
    return;
  }
}

#pragma mark -
- (void) mediaOverlayStatusChangedWithDictionary: (NSDictionary *) dictionary {  
  if (dictionary) {
  }
}

- (void)readiumInitialize
{
  if(![self.package.spineItems firstObject]) {
    self.bookIsCorrupt = YES;
    [self.delegate renderer:self didEncounterCorruptionForBook:self.book];
    return;
  } else {
    [self sequentiallyEvaluateJavaScript:@"simplified.shouldUpdateVisibilityOnUpdate = false;"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      self.webView.isAccessibilityElement = NO;
      [self sequentiallyEvaluateJavaScript:@"simplified.beginVisibilityUpdates();"];
      UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
    });
  }
  
  self.package.rootURL = [NSString stringWithFormat:@"http://127.0.0.1:%d/", self.server.port];
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
    [self calculateBookLength];
  });
  
  NSMutableDictionary *const dictionary = [NSMutableDictionary dictionary];
  dictionary[@"package"] = self.package.dictionary;
  dictionary[@"settings"] = [[NYPLReaderSettings sharedSettings] readiumSettingsRepresentation];
  
  NYPLBookLocation *const location = [[NYPLBookRegistry sharedRegistry]
                                      locationForIdentifier:self.book.identifier];
  if([location.renderer isEqualToString:renderer]) {
    // Readium stores a "contentCFI" but needs an "elementCfi" when handling a page request, so we
    // have to create a new dictionary.
    NSDictionary *const locationDictionary =
    NYPLJSONObjectFromData([location.locationString dataUsingEncoding:NSUTF8StringEncoding]);
	  
    NSString *contentCFI = locationDictionary[@"contentCFI"];
    if (!contentCFI) {
      contentCFI = @"";
    }
    dictionary[@"openPageRequest"] = @{@"idref": locationDictionary[@"idref"],
                                       @"elementCfi": contentCFI};
}
  
  NSData *data = NYPLJSONDataFromObject(dictionary);
  
  if(!data) {
    NYPLLOG(@"Failed to construct 'openBook' call.");
    return;
  }
  
//  var childs = $iframe.contentWindow.document.documentElement.getElementsByTagName('*');
//  console.log(childs);

  [self applyCurrentFlowDependentSettings];
  [self applyCurrentFlowIndependentSettings];
  self.loaded = YES;
  [self.delegate rendererDidFinishLoading:self];
  
  [self sequentiallyEvaluateJavaScript:
   [NSString stringWithFormat:@"ReadiumSDK.reader.openBook(%@)",
    [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]]];
  
  // this is so we can control the background colour of the media overlay highlighted text
  NSString * javascript = [NSString stringWithFormat:@" \
  window.nsRdHighlightColor = '%@'; \
  var reader = ReadiumSDK.reader; \
  var stylesheetText = function(color){return \".-epub-media-overlay-active {background-color: \" + color + \" !important;}\"}; \
  \
  \
  var eventCb = function($iframe, spineItem) { \
  var contentDoc = $iframe[0].contentDocument; \
  var $head = $('head', contentDoc); \
  var styleEl = contentDoc.createElement('style'); \
  styleEl.id = 'ns-rd-custom-styles'; \
  styleEl.type = 'text/css'; \
  styleEl.textContent = stylesheetText(window.nsRdHighlightColor); \
  $head.append(styleEl); \
  }; \
  \
  reader.off(ReadiumSDK.Events.CONTENT_DOCUMENT_LOADED, eventCb); \
  reader.on(ReadiumSDK.Events.CONTENT_DOCUMENT_LOADED, eventCb); \
  ", [NYPLConfiguration backgroundMediaOverlayHighlightColor].javascriptHexString] ;
  
  [self sequentiallyEvaluateJavaScript:javascript];
  [self syncLastReadingPosition];
}
- (void)syncLastReadingPosition
{
  Account *currentAccount = [[AccountsManager sharedInstance] currentAccount];
  if (currentAccount.syncIsEnabled) {
    NSMutableDictionary *const dictionary = [NSMutableDictionary dictionary];
    dictionary[@"package"] = self.package.dictionary;
    dictionary[@"settings"] = [[NYPLReaderSettings sharedSettings] readiumSettingsRepresentation];
    NYPLBookLocation *const location = [[NYPLBookRegistry sharedRegistry]
                                        locationForIdentifier:self.book.identifier];

    [self syncLastReadingPosition:dictionary andLocation:location andBook:self.book];
  }
}
- (void)syncLastReadingPosition:(NSMutableDictionary *const)dictionary andLocation:(NYPLBookLocation *const)location andBook:(NYPLBook *const)book
{
  [NYPLAnnotations sync:book completionHandler:^(NSDictionary * _Nullable responseObject) {
    
    NSString* serverLocationString;
    NSString* currentLocationString;
    NSString* timestampString;
    NSString* deviceIDString;
    UIAlertController *alertController;
    
    if (responseObject != nil)
    {
      NSDictionary *responseJSON = [NSJSONSerialization JSONObjectWithData:[responseObject[@"serverCFI"] dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
      deviceIDString = responseObject[@"device"];
      timestampString = responseObject[@"time"];
      serverLocationString = responseObject[@"serverCFI"];
      currentLocationString = location.locationString;
      NYPLLOG_F(@"serverLocationString %@",serverLocationString);
      NYPLLOG_F(@"currentLocationString %@",currentLocationString);
      NSDictionary *spineItemDetails = self.bookMapDictionary[responseJSON[@"idref"]];
      NSString * message=[NSString stringWithFormat:@"Would you like to go to the latest page read?\n\nChapter:\n\"%@\"",spineItemDetails[@"tocElementTitle"]];
   
      alertController = [UIAlertController alertControllerWithTitle:@"Sync Reading Position"
                                                                               message:message
                                                                        preferredStyle:UIAlertControllerStyleAlert];
      
      [alertController addAction:
       [UIAlertAction actionWithTitle:NSLocalizedString(@"NO", nil)
                                style:UIAlertActionStyleCancel
                              handler:^(__attribute__((unused))UIAlertAction * _Nonnull action) {
                                
                                self.postLastRead = YES;
                                
                              }]];
      
      [alertController addAction:
       [UIAlertAction actionWithTitle:NSLocalizedString(@"YES", nil)
                                style:UIAlertActionStyleDefault
                              handler:^(__attribute__((unused))UIAlertAction * _Nonnull action) {
                                
                                self.postLastRead = YES;
                                NSDictionary *const locationDictionary =
                                NYPLJSONObjectFromData([serverLocationString dataUsingEncoding:NSUTF8StringEncoding]);
                                
                                NSString *contentCFI = locationDictionary[@"contentCFI"];
                                if (!contentCFI) {
                                  contentCFI = @"";
                                }
                                dictionary[@"openPageRequest"] =
                                  @{@"idref": locationDictionary[@"idref"], @"elementCfi": contentCFI};
                                
                                
                                NSData *data = NYPLJSONDataFromObject(dictionary);
                                
                                [self sequentiallyEvaluateJavaScript:
                                 [NSString stringWithFormat:@"ReadiumSDK.reader.openBook(%@)",
                                  [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]]];
                                
                                NYPLLOG(@"opened server book location");
                                
                              }]];

    }
      if ((currentLocationString == nil && serverLocationString == nil) ||
          (currentLocationString != nil && serverLocationString == nil) ||
          (currentLocationString != nil && [deviceIDString isEqualToString:[NYPLAccount sharedAccount].deviceID]))
      {
        self.postLastRead = YES;
      }
      else if ((currentLocationString == nil && serverLocationString != nil) ||
               (![currentLocationString isEqualToString:serverLocationString]) ||
               (currentLocationString == nil && [deviceIDString isEqualToString:[NYPLAccount sharedAccount].deviceID]))
      {
        [[NYPLRootTabBarController sharedController] safelyPresentViewController:alertController animated:YES completion:nil];
      }
      else
      {
        self.postLastRead = YES;
      }
    
  }];
}

- (void) hasBookmarkForSpineItem:(NSString*)idref
{
  
  //  filter the bookmarks first by spine item (idref) and then run the result through a loop until there is a match
  // break out the loop if a match was found 
  
  
//  for (bookmark in filteredBookmarks) {
  

  // dummy cfi , replace by cfi from the bookmark in this loop 
  NSString *contentCFI = @"/4/2/2";
  
  NSString *js = [NSString stringWithFormat:@"ReadiumSDK.reader.isVisibleSpineItemElementCfi('%@', '%@')",
                  idref,
                  contentCFI];
  
  NYPLLOG(js);
  
  [self
   sequentiallyEvaluateJavaScript:js
   withCompletionHandler:^(id  _Nullable result, NSError * _Nullable error) {
     
     if (!error)
     {
       NSNumber const *isBookmarked = result;
       NYPLLOG(isBookmarked);
       if (isBookmarked && ![isBookmarked  isEqual: @0])
       {
         // is not a bookmarked page
         NYPLLOG(@"there is a bookmark for this page");
       }
       else
       {
         // is not a bookmarked page
         
         NYPLLOG(@"there is no bookmark for this page");
       }
       
     }
     else{
       NYPLLOG(error);
     }
     
   }];
  
  // end loop
//  }
  
  
}

- (void)readiumPaginationChangedWithDictionary:(NSDictionary *const)dictionary
{
  // Use left-to-right unless it explicitly asks for right-to-left.
  self.pageProgressionIsLTR = ![dictionary[@"pageProgressionDirection"]
                                isEqualToString:@"rtl"];
  self.canGoLeft = [dictionary[@"canGoLeft_"] boolValue];
  self.canGoRight = [dictionary[@"canGoRight_"] boolValue];
  
  NSArray *const openPages = dictionary[@"openPages"];
  
  self.openPageCount = openPages.count;

  __weak NYPLReaderReadiumView *const weakSelf = self;
  
  [UIView beginAnimations:@"animations" context:NULL];
  [UIView setAnimationDuration:0.25];
  weakSelf.webView.alpha = 1.0;
  [UIView commitAnimations];
  
  UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.webView);
  
  [self sequentiallyEvaluateJavaScript:@"simplified.pageDidChange();"];
  
  self.isPageTurning = NO;
  
  // Readium needs a moment...
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [self
     sequentiallyEvaluateJavaScript:@"ReadiumSDK.reader.bookmarkCurrentPage()"
     withCompletionHandler:^(id  _Nullable result, __unused NSError *_Nullable error) {
       if(!result) {
         NYPLLOG(@"Readium failed to generate a CFI. This is a bug in Readium.");
         return;
       }
       NSString *const locationJSON = result;
       BOOL completed = NO;
       if (openPages.count>0 && [locationJSON rangeOfString:openPages[0][@"idref"]].location != NSNotFound) {
         completed = YES;
       }
       NYPLLOG(locationJSON);
       
//       NSError *jsonError;
//       NSData *objectData = [locationJSON dataUsingEncoding:NSUTF8StringEncoding];
//       NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
//                                                            options:NSJSONReadingMutableContainers
//                                                              error:&jsonError];

//       [self hasBookmarkForSpineItem:json[@"idref"]];
       
       NYPLBookLocation *const location = [[NYPLBookLocation alloc]
                                           initWithLocationString:locationJSON
                                           renderer:renderer];
       
       [weakSelf calculateProgressionWithDictionary:dictionary withHandler:^{
         [weakSelf.delegate
          renderer:weakSelf
          didUpdateProgressWithinBook:weakSelf.progressWithinBook
          pageIndex:weakSelf.spineItemPageIndex
          pageCount:weakSelf.spineItemPageCount
          spineItemTitle:weakSelf.spineItemDetails[@"tocElementTitle"]];
       }];
       
       if(location) {
         [[NYPLBookRegistry sharedRegistry]
          setLocation:location
          forIdentifier:weakSelf.book.identifier];
         }
       if(self.postLastRead) {
         [NYPLAnnotations postLastRead:weakSelf.book cfi:location.locationString];
       }
     }];
  });
}

- (void)calculateBookLength
{
  NSDecimalNumber *totalLength = [NSDecimalNumber zero];
  
  NSMutableDictionary *bookDicts = [[NSMutableDictionary alloc] init];
  
  for (RDSpineItem *spineItem in self.package.spineItems) {
    if ([spineItem.mediaType isEqualToString:@"application/xhtml+xml"]) {
      NSURL *url =[NSURL URLWithString:[self.server.package.rootURL stringByAppendingPathComponent:spineItem.baseHref]];
      
      NSDecimalNumber *expectedLengthDec = [NSDecimalNumber zero];
      NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
      request.HTTPMethod = @"HEAD";
      NSHTTPURLResponse *response;
      NSError *headError;
      int responseStatusCode = 0;
      [NSURLConnection sendSynchronousRequest: request returningResponse: &response error: &headError];
      if ([response respondsToSelector:@selector(allHeaderFields)]) {
        
        responseStatusCode = (int)[response statusCode];
        if (!headError && responseStatusCode == 200 ) {
          NSNumber *length = [NSNumber numberWithLongLong:[response expectedContentLength]];
          expectedLengthDec = [NSDecimalNumber decimalNumberWithDecimal:length.decimalValue];
        }
      }
    
      if (headError || responseStatusCode != 200) {
        NSError *dataError;
        NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&dataError];
        
        if (data || !dataError) {
          NSNumber *length = [NSNumber numberWithUnsignedInteger:data.length];
          expectedLengthDec = [NSDecimalNumber decimalNumberWithDecimal:length.decimalValue];
        }
      }
      
      NSMutableDictionary *spineItemDict = [[NSMutableDictionary alloc] init];
      [spineItemDict setObject:expectedLengthDec forKey:@"spineItemBytesLength"];
      [spineItemDict setObject:spineItem.baseHref forKey:@"spineItemBaseHref"];
      [spineItemDict setObject:spineItem.idref forKey:@"spineItemIdref"];
      [spineItemDict setObject:totalLength forKey:@"totalLengthSoFar"];
      
      NSString *title = [self tocTitleForSpineItem:spineItem];
      if (title && [[title class] isSubclassOfClass:[NSString class]]) {
        [spineItemDict setObject:title forKey:@"tocElementTitle"];
      }
      else {
        [spineItemDict setObject:NSLocalizedString(@"chapter", nil) forKey:@"tocElementTitle"];
      }
      
      [bookDicts setObject:spineItemDict forKey:spineItem.idref];
      totalLength = [totalLength decimalNumberByAdding: expectedLengthDec];
    }
  }
  
  [bookDicts setObject:totalLength forKey:@"totalLength"];
  
  self.bookMapDictionary = bookDicts;
}

- (NSString *) tocTitleForSpineItem: (RDSpineItem *) spineItem {
  for (RDNavigationElement *tocElement in self.package.tableOfContents.children) {
    if ([tocElement.content containsString:spineItem.baseHref]) {
      return tocElement.title;
    }
  }
  return nil;
}

- (void)calculateProgressionWithDictionary:(NSDictionary *const)dictionary
                               withHandler:(void(^ const)())handler
{
  if (!self.bookMapDictionary) return;
  
  NSArray *const openPages = dictionary[@"openPages"];
  if(openPages.count == 0) {
    NYPLLOG(@"Did not receive expected information on open pages.");
    return;
  }
  
  NSDictionary *const openPage = [openPages firstObject];
  
  NSString *const idref = openPage[@"idref"];
  if(!idref) {
    NYPLLOG(@"Did not receive idref.");
    return;
  }
  
  NSUInteger const spineItemCount = [dictionary[@"spineItemCount"] unsignedIntegerValue];
  if(!spineItemCount) {
    NYPLLOG(@"Did not receive spine item count.");
    return;
  }
  
  NSUInteger const spineItemIndex = [openPage[@"spineItemIndex"] unsignedIntegerValue];
  
  self.progressWithinBook = spineItemIndex / (float)spineItemCount;
  self.spineItemPageCount = [openPage[@"spineItemPageCount"] unsignedIntegerValue];
  self.spineItemPageIndex = [openPage[@"spineItemPageIndex"] unsignedIntegerValue];
  self.spineItemDetails = self.bookMapDictionary[idref];
  
  if (handler) handler();
}

// This method will call itself repeatedly every |readyStateCheckIntervalInSeconds|.
- (void)pollReadyState
{
  if(self.secondsSinceComplete > 0.2 && !self.performingLongLoad) {
    self.performingLongLoad = YES;
    [self.delegate rendererDidBeginLongLoad:self];
  }
  
  self.secondsSinceComplete += readyStateCheckIntervalInSeconds;
  
  [self.webView
   evaluateJavaScript:@"window.frames[\"epubContentIframe\"].document.readyState"
   completionHandler:^(id _Nullable result, __unused NSError *_Nullable error) {
     if([result isEqualToString:@"complete"]) {
       self.secondsSinceComplete = 0.0;
       if(self.performingLongLoad) {
         self.performingLongLoad = NO;
         [self.delegate renderDidEndLongLoad:self];
       }
     }
   }];
  
  dispatch_time_t const dispatchTime =
    dispatch_time(DISPATCH_TIME_NOW, (int64_t)(readyStateCheckIntervalInSeconds * NSEC_PER_SEC));
  
  dispatch_after(dispatchTime, dispatch_get_main_queue(), ^{
    [self pollReadyState];
  });
}

#pragma mark NYPLReaderRenderer

- (NSArray *)TOCElements
{
  if(_TOCElements) return _TOCElements;
  
  NSMutableArray *const TOCElements = [NSMutableArray array];
  generateTOCElements(self.package.tableOfContents.children, 0, TOCElements);
  
  _TOCElements = TOCElements;
  
  return _TOCElements;
}

- (void)openOpaqueLocation:(NYPLReaderRendererOpaqueLocation *const)opaqueLocation
{
  if(![(id)opaqueLocation isKindOfClass:[RDNavigationElement class]]) {
    @throw NSInvalidArgumentException;
  }
  
  RDNavigationElement *const navigationElement = (RDNavigationElement *)opaqueLocation;
  
  [self sequentiallyEvaluateJavaScript:
   [NSString stringWithFormat:@"ReadiumSDK.reader.openContentUrl('%@', '%@')",
    navigationElement.content,
    navigationElement.sourceHref]];
}

- (BOOL) bookHasMediaOverlays {
  /*
  NSString *isAvailable = [self.webView stringByEvaluatingJavaScriptFromString:
                           @"ReadiumSDK.reader.isMediaOverlayAvailable()"];
  if ( [isAvailable containsString:@"true"]) {
    return YES;
  }
  else {
    return NO;
  }
  */
  return NO;
}

- (BOOL) bookHasMediaOverlaysBeingPlayed {
  /*
  if (![self bookHasMediaOverlays]) {
    return NO;
  }
  
  NSString *isPlaying = [self.webView stringByEvaluatingJavaScriptFromString:
                         @"ReadiumSDK.reader.isPlayingMediaOverlay()"];
  if ( isPlaying.length == 0) {
    return NO;
  }
  else {
    return YES;
  }
  */
  return NO;
}

- (void)sequentiallyEvaluateJavaScript:(NSString *const)javaScript
                 withCompletionHandler:(void (^_Nullable)(id _Nullable result,
                                                          NSError *_Nullable error))handler
{
  // We run this as a new operation to let the caller get back to
  // whatever it's doing ASAP.
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    @synchronized(self) {
      if(self.javaScriptIsRunning) {
        // Some JavaScript is already running so we add this to the
        // queue and finish.
        [self.javaScriptStringQueue addObject:javaScript];
        if(handler) {
          [self.javaScriptHandlerQueue addObject:handler];
        } else {
          [self.javaScriptHandlerQueue addObject:[NSNull null]];
        }
      } else {
        self.javaScriptIsRunning = YES;
        [self.webView
         evaluateJavaScript:javaScript
         completionHandler:^(id _Nullable result, NSError * _Nullable error) {
           @synchronized(self) {
             self.javaScriptIsRunning = NO;
             if(handler) {
               [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                 handler(result, error);
               }];
             }
             if(self.javaScriptStringQueue.count > 0) {
               NSString *const nextJavaScript = [self.javaScriptStringQueue firstObject];
               [self.javaScriptStringQueue removeObjectAtIndex:0];
               id const nextHandler = [self.javaScriptHandlerQueue firstObject];
               [self.javaScriptHandlerQueue removeObjectAtIndex:0];
               [self sequentiallyEvaluateJavaScript:nextJavaScript
                              withCompletionHandler:NYPLNullToNil(nextHandler)];
             }
           }
         }];
      }
    }
  }];
}

- (void)sequentiallyEvaluateJavaScript:(nonnull NSString *const)javaScript
{
  [self sequentiallyEvaluateJavaScript:javaScript withCompletionHandler:nil];
}

@end
