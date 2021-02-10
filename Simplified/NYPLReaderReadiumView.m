@import WebKit;

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
#import "NYPLLOG.h"
#import "NYPLReaderReadiumView.h"
#import "UIColor+NYPLColorAdditions.h"
#import "NSURL+NYPLURLAdditions.h"
#import "NYPLConfiguration.h"
#import "NYPLRootTabBarController.h"
#import "NSDate+NYPLDateAdditions.h"
#import "NYPLReachability.h"
#import "NYPLReadiumViewSyncManager.h"

#import "SimplyE-Swift.h"

//==============================================================================
#pragma mark - Web View

@interface NYPLWebView: WKWebView
@end

@implementation NYPLWebView

// On Open eBooks we have a requirement to not allow copying of book text
#ifdef OPENEBOOKS
-(BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
  // Note: this does not work on iOS <= 10: the callback is never called for
  // the copy: action. It is on iOS 11+.
  if (action == @selector(copy:)) {
    return NO;
  }
  return [super canPerformAction:action withSender:sender];
}
#endif

@end

//==============================================================================
#pragma mark - Backing View Class Extension

@interface NYPLReaderReadiumView ()
  <NYPLReaderRenderer, RDPackageResourceServerDelegate, NYPLReadiumViewSyncManagerDelegate, NYPLBackgroundWorkOwner, WKNavigationDelegate, WKUIDelegate>

@property (nonatomic) NYPLBook *book;
@property (nonatomic) BOOL bookIsCorrupt;
@property (nonatomic) RDContainer *container;
@property (nonatomic) NYPLReaderContainerDelegate *containerDelegate;
@property (nonatomic) BOOL loaded;
@property (nonatomic) NSInteger openPageCount;
@property (nonatomic) RDPackage *package;
@property (nonatomic) BOOL pageProgressionIsLTR;
@property (nonatomic) BOOL isPageTurning, canGoLeft, canGoRight;
@property (nonatomic) RDPackageResourceServer *server;
@property (nonatomic) NSArray *TOCElements;
@property (nonatomic) NSArray<NYPLReadiumBookmark *> *bookmarkElements;
@property (nonatomic) NYPLWebView *webView;

@property (nonatomic) NSDictionary *bookMapDictionary;
@property (nonatomic) NSUInteger spineItemPageIndex;
@property (nonatomic) NSUInteger spineItemPageCount;
@property (nonatomic) float progressWithinBook; // [0, 1]
@property (nonatomic) NSDictionary *spineItemDetails;

@property (nonatomic) BOOL javaScriptIsRunning;
@property (nonatomic) NSMutableArray *javaScriptHandlerQueue;
@property (nonatomic) NSMutableArray *javaScriptStringQueue;
@property (copy) dispatch_block_t backgroundWorkItem;

@property (nonatomic) double secondsSinceComplete;
@property (nonatomic) BOOL performingLongLoad;
@property (nonatomic) BOOL updateSettingsInProgress;

@property (nonatomic) NYPLBackgroundExecutor *backgroundHelper;
@end

static NSString *const localhost = @"127.0.0.1";
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
                         stringByRemovingPercentEncoding]
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

//==============================================================================
#pragma mark - Backing View

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
  
  CGRect webviewFrame;
  if (@available (iOS 11.0, *)) {
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    webviewFrame = CGRectMake(0,
                              60 + window.safeAreaInsets.top,
                              self.bounds.size.width,
                              self.bounds.size.height - 100 - window.safeAreaInsets.top - window.safeAreaInsets.bottom);
  } else {
    webviewFrame = CGRectMake(0, 60, self.bounds.size.width, self.bounds.size.height - 100);
  }

  self.webView = [[NYPLWebView alloc] initWithFrame:webviewFrame];
  self.webView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                   UIViewAutoresizingFlexibleWidth);
  self.webView.navigationDelegate = self;
  self.webView.UIDelegate = self;
  self.webView.scrollView.bounces = NO;
  if (@available(iOS 11, *)) {
    // Prevent content from shifting when toggling the status bar.
    self.webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
  }
  self.webView.alpha = 0.0;
  [self addSubview:self.webView];
  
  self.webView.isAccessibilityElement = YES;
  [self.webView loadRequest:
   [NSURLRequest requestWithURL:
    [NSURL URLWithString:
     [NSString stringWithFormat:
      @"http://%@:%d/simplified-readium/reader.html",
      localhost,
      self.server.port]]]];
  
  [self addObservers];
  
  self.backgroundColor = [NYPLReaderSettings sharedSettings].backgroundColor;
  
  self.javaScriptIsRunning = NO;
  self.javaScriptHandlerQueue = [NSMutableArray array];
  self.javaScriptStringQueue = [NSMutableArray array];
  
  self.backgroundHelper = [[NYPLBackgroundExecutor alloc]
                           initWithOwner:self taskName:@"NYPLReadiumInit"];
  return self;
}

- (void)addObservers
{
  // TODO: see UserSettingsNavigationController::appearanceDidChange(to:)
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(applyCurrentFlowIndependentSettings)
   name:NYPLReaderSettingsColorSchemeDidChangeNotification
   object:nil];
  
  // TODO: see UserSettingsNavigationController::fontDidChange(to:)
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(applyCurrentFlowIndependentSettings)
   name:NYPLReaderSettingsFontFaceDidChangeNotification
   object:nil];

  // TODO: see UserSettingsNavigationController::fontSizeDidChange(increase:)
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
   selector:@selector(willResignActive)
   name:UIApplicationWillResignActiveNotification
   object:nil];
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(didBecomeActive)
   name:UIApplicationDidBecomeActiveNotification
   object:nil];

  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(didEnterBackground)
   name:UIApplicationDidEnterBackgroundNotification
   object:nil];
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(didChangePasteboard)
   name:UIPasteboardChangedNotification
   object:nil];
}

- (void)didChangePasteboard
{
#ifdef OPENEBOOKS
  if (@available(iOS 11, *)) {
    // nothing to do because NYPLWebView successfully hides the Copy action
    // on iOS 11+.
  } else {
    // disable notification temporarily to avoid infinite loop
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:UIPasteboardChangedNotification
     object:nil];

    // This is necessary for iOS <= 10 because of a bug in iOS, where the Copy
    // action unfortunately is still displayed. The workaround here is to
    // essentially "copy nothing".
    // Note: Discarding the previous pasteboard string is consistent with
    // the user's action because they did effectively select Copy, so they
    // would have lost the previous pasteboard contents anyway.
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    [pasteboard setString:@""];

    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(didChangePasteboard)
     name:UIPasteboardChangedNotification
     object:nil];
  }
#endif
  [self clearTextSelection];
}

- (void)applyReaderSettings
{
    NSString *const javaScript = [NSString stringWithFormat:
                                  @"ReadiumSDK.reader.updateSettings(%@)",
                                  [[NSString alloc]
                                   initWithData:NYPLJSONDataFromObject([[NYPLReaderSettings sharedSettings]
                                                                        readiumSettingsRepresentation])
                                   encoding:NSUTF8StringEncoding]];
    [self sequentiallyEvaluateJavaScript:javaScript];
}

- (void)applyCurrentFlowDependentSettings
{
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    if (self.updateSettingsInProgress) {
      NYPLLOG(@"rate limiting..");
      return;
    }
    self.updateSettingsInProgress = YES;
    NSString *const javaScript = [NSString stringWithFormat:
                                  @"ReadiumSDK.reader.updateSettings(%@)",
                                  [[NSString alloc]
                                   initWithData:NYPLJSONDataFromObject([[NYPLReaderSettings sharedSettings]
                                                                        readiumSettingsRepresentation])
                                   encoding:NSUTF8StringEncoding]];
    [self sequentiallyEvaluateJavaScript:@"simplified.saveLocationBeforeSettingsUpdate();"];
    [self sequentiallyEvaluateJavaScript:javaScript];
    [self sequentiallyEvaluateJavaScript:@"simplified.applyLocationAferSettingsUpdate();"];
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
  }];
}

- (void)applyBackgroundMediaOverlayHighlightColor {
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

- (void)didEnterBackground
{
  if (self.backgroundWorkItem) {
    if (dispatch_block_testcancel(self.backgroundWorkItem) == NO) {
      dispatch_block_cancel(self.backgroundWorkItem);
    }
  }
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

/// Toggles user interaction to ensure text selections are cleared.
- (void)clearTextSelection {
  self.webView.userInteractionEnabled = !self.webView.userInteractionEnabled;
  self.webView.userInteractionEnabled = !self.webView.userInteractionEnabled;
}

#pragma mark NSObject

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.webView.UIDelegate = nil;
  self.webView.navigationDelegate = nil;
  NYPLLOG(@"NYPLReaderReadiumView was deallocated.");
}

#pragma mark RDPackageResourceServerDelegate

- (void)
packageResourceServer:(__attribute__((unused)) RDPackageResourceServer *)packageResourceServer
executeJavaScript:(NSString *const)javaScript
{
  [self sequentiallyEvaluateJavaScript:javaScript];
}

#pragma mark WKNavigationDelegate

- (WKWebView *)webView:(__unused WKWebView *)webView
createWebViewWithConfiguration:(__unused WKWebViewConfiguration *)configuration
   forNavigationAction:(WKNavigationAction *)navigationAction
        windowFeatures:(__unused WKWindowFeatures *)windowFeatures
{
  if([navigationAction.request.URL.host isEqualToString:localhost]) {
    // We don't want to ever open such things in an external browser so we cancel the
    // request. It's not clear why we'd end up here but doing nothing is better than
    // switching to Safari and failing. (Keep in mind that this delegate method is only
    // called when we MUST either create a new web view or cancel the request: Opening
    // the request in the existing web view is not an option.)
    return nil;
  }
  
  // Since this is very likely a link to a web page, a mailto: URL, or similar, let
  // Safari handle it.
  [[UIApplication sharedApplication] openURL:navigationAction.request.URL
                                     options:@{}
                           completionHandler:nil];
  
  // Cancel the request.
  return nil;
}

// called when going into reading a book. May be called multiple times for same book
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
    NSArray *const components = [request.URL.resourceSpecifier componentsSeparatedByString:@"/"];
    NSString *const function = components[0];
    if([function isEqualToString:@"gesture-left"]) {
      [self clearTextSelection];
      [self sequentiallyEvaluateJavaScript:@"ReadiumSDK.reader.openPageLeft()"];
    } else if([function isEqualToString:@"gesture-right"]) {
      [self clearTextSelection];
      [self sequentiallyEvaluateJavaScript:@"ReadiumSDK.reader.openPageRight()"];
    } else if([function isEqualToString:@"gesture-center"]) {
      if ([UIMenuController sharedMenuController].isMenuVisible) {
        [self clearTextSelection];
      } else {
        [self.delegate
         renderer:self
         didReceiveGesture:NYPLReaderRendererGestureToggleUserInterface];
      }
    } else {
      NYPLLOG(@"Ignoring unknown simplified function.");
    }
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
    } else if([function isEqualToString:@"settings-applied"]) {
      NYPLLOG(@"Readium: Settings Applied.");
    } else {
      NYPLLOG(@"Readium: Ignoring unknown function.");
    }
    decisionHandler(WKNavigationActionPolicyCancel);
    return;
  }
  
  else {
    if (request.URL.isNYPLExternal) {
      [[UIApplication sharedApplication] openURL:(NSURL *__nonnull)request.URL
                                         options:@{}
                               completionHandler:nil];
      decisionHandler(WKNavigationActionPolicyCancel);
      return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
    return;
  }
}

#pragma mark - ReadiumViewSyncManagerDelegate Methods

- (void)patronDecidedNavigation:(BOOL)toLatestPage withNavDict:(NSDictionary *)dict
{
  if (toLatestPage == YES) {
    NSData *data = NYPLJSONDataFromObject(dict);
    [self sequentiallyEvaluateJavaScript:
     [NSString stringWithFormat:@"ReadiumSDK.reader.openBook(%@)",
      [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]]];
  }
}

- (void)uploadFinishedForBookmark:(NYPLReadiumBookmark *)bookmark
                          inBook:(NSString *)bookID
{
  NYPLBookRegistry *registry = [NYPLBookRegistry sharedRegistry];
  [registry addReadiumBookmark:bookmark forIdentifier:bookID];
  self.bookmarkElements = [registry readiumBookmarksForIdentifier:bookID];
}

#pragma mark -

- (void)readiumInitialize
{
  __weak NYPLReaderReadiumView *weakSelf = self;

  if(![self.package.spineItems firstObject]) {
    self.bookIsCorrupt = YES;
    [self.delegate renderer:self didEncounterCorruptionForBook:self.book];
    return;
  }

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    weakSelf.webView.isAccessibilityElement = NO;
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
  });

  self.package.rootURL = [NSString stringWithFormat:@"http://%@:%d/", localhost, self.server.port];

  NSMutableDictionary *const dictionary = [NSMutableDictionary dictionary];
  dictionary[@"package"] = self.package.dictionary;
  dictionary[@"settings"] = [[NYPLReaderSettings sharedSettings] readiumSettingsRepresentation];
  
  NYPLBookLocation *const location = [[NYPLBookRegistry sharedRegistry] locationForIdentifier:self.book.identifier];
  if([location.renderer isEqualToString:renderer]) {
    NSDictionary *const locationDictionary = NYPLJSONObjectFromData([location.locationString dataUsingEncoding:NSUTF8StringEncoding]);
    NSString *contentCFI = locationDictionary[@"contentCFI"];
    if (!contentCFI) {
      contentCFI = @"";
      [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeNilCFI
                                summary:@"R1 eReader warning: no CFI from NYPLLocation"
                               metadata:@{
                                 @"Book": self.book.loggableDictionary ?: @"N/A",
                                 @"Registry locationString": location.locationString ?: @"N/A",
                                 @"renderer": location.renderer ?: @"N/A",
                                 @"openPageRequest idref": locationDictionary[@"idref"] ?: @"N/A",
                               }];
    }
    dictionary[@"openPageRequest"] = @{@"idref": locationDictionary[@"idref"], @"elementCfi": contentCFI};
    NYPLLOG_F(@"Readium Initialize: Open Page Req idref: %@ elementCfi: %@", locationDictionary[@"idref"], contentCFI);
  }
  
  NSData *data = NYPLJSONDataFromObject(dictionary);
  if(!data) {
    NYPLLOG(@"Failed to construct 'openBook' call.");
    return;
  }

  [self applyReaderSettings];
  [self applyCurrentFlowIndependentSettings];
  [self applyBackgroundMediaOverlayHighlightColor];

  NSString *openBookJavascript = [NSString stringWithFormat:@"ReadiumSDK.reader.openBook(%@)",
                                  [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
  [self sequentiallyEvaluateJavaScript:openBookJavascript];

  [self.backgroundHelper dispatchBackgroundWork];

  self.loaded = YES;
  [self.delegate rendererDidFinishLoading:self];
}

/// Executes expensive / long running initialization tasks:
///   - on background queue: generate book length dictionary
///   - then on main queue: initialize sync manager
- (void)performBackgroundWork
{
  NYPLLOG(@"Performing init background work for Readium view...");
  self.bookMapDictionary = [self generateBookDictionary];

  dispatch_sync(dispatch_get_main_queue(), ^{
    self.syncManager = [[NYPLReadiumViewSyncManager alloc]
                        initWithBookID:self.book.identifier
                        annotationsURL:self.book.annotationsURL
                        bookMap:self.bookMapDictionary
                        delegate:self];
    [self.syncManager syncAllAnnotationsWithPackage:self.package.dictionary];
  });
}

- (dispatch_block_t)setUpWorkItemWrappingBackgroundWork:(void (^ _Nonnull)(void))backgroundWork
{
  __weak NYPLReaderReadiumView *weakSelf = self;
  self.backgroundWorkItem = dispatch_block_create(0, ^{
    backgroundWork();
    weakSelf.backgroundWorkItem = nil;
  });
  return self.backgroundWorkItem;
}

- (void)checkForExistingBookmarkAtLocation:(NSString*)idref
                         completionHandler:(void(^)(BOOL success, NYPLReadiumBookmark *bookmark))completionHandler
{

  completionHandler(NO, nil);   //Remove bookmark icon at beginning of page turn
  
  NSArray *bookmarks = [[NYPLBookRegistry sharedRegistry] readiumBookmarksForIdentifier:self.book.identifier];
  for (NYPLReadiumBookmark *bookmark in bookmarks) {
    if ([bookmark.idref isEqualToString:idref]) {
      NSString *js = [NSString stringWithFormat:@"ReadiumSDK.reader.isVisibleSpineItemElementCfi('%@', '%@')",
                      bookmark.idref,
                      bookmark.contentCFI];
    
      [self sequentiallyEvaluateJavaScript:js
        withCompletionHandler:^(id  _Nullable result, NSError * _Nullable error) {
        if (!error) {
          NSNumber const *isBookmarked = result;
          NYPLLOG_F(@"Bookmark exists at book location: %@", bookmark.contentCFI);
          if (isBookmarked && ![isBookmarked isEqual: @0]) {
            completionHandler(YES, bookmark);
            return;
          }
        } else {
          NYPLLOG_F(@"JS Error: %@", error);
        }
      }];
    }
  }
}

- (NSString*) currentChapter
{
  NYPLBookRegistry *registry = [NYPLBookRegistry sharedRegistry];
  NYPLBookLocation *location = [registry locationForIdentifier:self.book.identifier];
  NSData *data = [location.locationString dataUsingEncoding:NSUTF8StringEncoding];
  if (data) {
    NSDictionary *const locationDictionary = NYPLJSONObjectFromData(data);
    NSString *idref = locationDictionary[@"idref"];
    return self.bookMapDictionary[idref][@"tocElementTitle"];
  } else {
    return nil;
  }
}

- (void)addBookmark
{
  NYPLBookRegistry *registry = [NYPLBookRegistry sharedRegistry];
  NYPLBookLocation *location = [registry locationForIdentifier:self.book.identifier];
  NSDictionary *locationDictionary;
  if (location.locationString) {
    locationDictionary = NYPLJSONObjectFromData([location.locationString dataUsingEncoding:NSUTF8StringEncoding]);
  }
  NSString *contentCFI = NYPLNullToNil(locationDictionary[@"contentCFI"]);
  NSString *idref = NYPLNullToNil(locationDictionary[@"idref"]);
  NSString *chapter = self.bookMapDictionary[idref][@"tocElementTitle"];

  float progressWithinChapter = 0.0;
  if (self.spineItemPageIndex > 0 && self.spineItemPageCount > 0) {
    progressWithinChapter = (float) self.spineItemPageIndex / (float) self.spineItemPageCount;
  }

  NYPLReadiumBookmark *bookmark = [[NYPLReadiumBookmark alloc]
                                  initWithAnnotationId:nil
                                  contentCFI:contentCFI
                                  idref:idref
                                  chapter:chapter
                                  page:nil
                                  location:location.locationString
                                  progressWithinChapter:progressWithinChapter
                                  progressWithinBook:self.progressWithinBook
                                  time:nil
                                  device:[[NYPLUserAccount sharedAccount] deviceID]];
  
  if (bookmark) {
    [self.delegate updateBookmarkIcon:YES];
    [self.delegate updateCurrentBookmark:bookmark];
    [self.syncManager addBookmark:bookmark withCFI:location.locationString forBook:self.book.identifier];
  } else {
    UIAlertController *alert = [NYPLAlertUtils alertWithTitle:@"Bookmarking Error" message:@"A bookmark could not be created on the current page."];
    UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:action];
    [NYPLAlertUtils presentFromViewControllerOrNilWithAlertController:alert viewController:nil animated:YES completion:nil];
  }
}

- (void)deleteBookmark:(NYPLReadiumBookmark*)bookmark
{
  NYPLBookRegistry *registry = [NYPLBookRegistry sharedRegistry];
  [registry deleteReadiumBookmark:bookmark forIdentifier:self.book.identifier];
  
  [self.delegate updateBookmarkIcon:NO];
  [self.delegate updateCurrentBookmark:nil];
  
  self.bookmarkElements = [registry readiumBookmarksForIdentifier:self.book.identifier];
  
  Account *currentAccount = [[AccountsManager sharedInstance] currentAccount];

  if (currentAccount.details.syncPermissionGranted && bookmark.annotationId.length > 0) {
    [NYPLAnnotations deleteBookmarkWithAnnotationId:bookmark.annotationId
                                  completionHandler:^(BOOL success) {
                                    if (success) {
                                      NYPLLOG(@"Bookmark successfully deleted");
                                    } else {
                                      NYPLLOG(@"Failed to delete bookmark from server. Will attempt again on next Sync");
                                    }
                                  }];
  } else {
    NYPLLOG(@"Delete on Server skipped: Sync is not enabled or Annotation ID did not exist for bookmark.");
  }
}

- (void)readiumPaginationChangedWithDictionary:(NSDictionary *const)dictionary
{
  // Use left-to-right unless it explicitly asks for right-to-left.
  self.pageProgressionIsLTR = ![dictionary[@"pageProgressionDirection"]
                                isEqualToString:@"rtl"];
  self.canGoLeft = [dictionary[@"canGoLeft_"] boolValue];
  self.canGoRight = [dictionary[@"canGoRight_"] boolValue];

  if (self.updateSettingsInProgress) {
    // Readium cannot maintain a CFI with rapid changes to Reader Settings.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      self.updateSettingsInProgress = NO;
    });
  }
  
  NSArray *const openPages = dictionary[@"openPages"];
  self.openPageCount = openPages.count;

  [UIView beginAnimations:@"animations" context:NULL];
  [UIView setAnimationDuration:0.25];
  self.webView.alpha = 1.0;
  [UIView commitAnimations];
  
  UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.webView);

  [self sequentiallyEvaluateJavaScript:@"simplified.pageDidChange();"];
  
  self.isPageTurning = NO;

  __weak NYPLReaderReadiumView *const weakSelf = self;
  // Readium needs a moment...
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [weakSelf
     sequentiallyEvaluateJavaScript:@"ReadiumSDK.reader.bookmarkCurrentPage()"
     withCompletionHandler:^(id  _Nullable result, __unused NSError *_Nullable error) {

       if(!result || [result isKindOfClass:[NSNull class]]) {
         NYPLLOG(@"Readium failed to generate a CFI. This is a bug in Readium 1.");
         [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeNilCFI
                                   summary:@"eReader bug: R1 failed to generate CFI"
                                  metadata:@{
                                    @"Book": self.book.loggableDictionary ?: @"N/A",
                                  }];
         return;
       }
       NSString *const locationJSON = result;
       NYPLLOG(locationJSON);
       
       NSError *jsonError;
       NSData *objectData = [locationJSON dataUsingEncoding:NSUTF8StringEncoding];
       NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                            options:NSJSONReadingMutableContainers
                                                              error:&jsonError];

       [weakSelf checkForExistingBookmarkAtLocation:json[@"idref"] completionHandler:^(BOOL success, NYPLReadiumBookmark *bookmark) {
         [weakSelf.delegate updateBookmarkIcon:success];
         [weakSelf.delegate updateCurrentBookmark:bookmark];
       }];

       [weakSelf calculateProgressionWithDictionary:dictionary withHandler:^{
         [weakSelf.delegate
          renderer:weakSelf
          didUpdateProgressWithinBook:weakSelf.progressWithinBook
          pageIndex:weakSelf.spineItemPageIndex
          pageCount:weakSelf.spineItemPageCount
          spineItemTitle:weakSelf.spineItemDetails[@"tocElementTitle"]];
       }];

       NYPLBookLocation *const location = [[NYPLBookLocation alloc] initWithLocationString:locationJSON renderer:renderer];
       NSString *const bookID = weakSelf.book.identifier;

       if (![location.locationString containsString:@"null"] && bookID) {
         [[NYPLBookRegistry sharedRegistry] setLocation:location forIdentifier:bookID];
         [weakSelf.syncManager postLastReadPosition:location.locationString];
       } else {
         NYPLLOG(@"Ignoring Readium CFI output containing \"null\"");
       }
     }];
  });
}

/**
 This method generates the bookMapDictionary synchronously: therefore since
 it's an expensive operation, it should be called on a background queue,
 or at least not on the main queue.
 */
- (NSDictionary *)generateBookDictionary
{
  NSDecimalNumber *totalLength = [NSDecimalNumber zero];
  NSMutableDictionary *bookDicts = [[NSMutableDictionary alloc] init];

  for (RDSpineItem *spineItem in self.package.spineItems) {

    if (self.backgroundWorkItem) {
      if (dispatch_block_testcancel(self.backgroundWorkItem)) {
        return nil; // bail since the dispatch block was canceled
      }
    }

    if ([spineItem.mediaType isEqualToString:@"application/xhtml+xml"]) {
      NSURL *url =[NSURL URLWithString:[self.server.package.rootURL stringByAppendingPathComponent:spineItem.baseHref]];
      
      NSDecimalNumber *expectedLengthDec = [NSDecimalNumber zero];
      NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
      request.HTTPMethod = @"HEAD";
      NSHTTPURLResponse *response;
      NSError *headError;
      int responseStatusCode = 0;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
      // TODO: SIMPLY-2589
      [NSURLConnection sendSynchronousRequest: request returningResponse: &response error: &headError];
#pragma clang diagnostic pop

      if ([response respondsToSelector:@selector(allHeaderFields)]) {
        
        responseStatusCode = (int)[response statusCode];
        if (!headError && responseStatusCode == 200 ) {
          NSNumber *length = [NSNumber numberWithLongLong:[response expectedContentLength]];
          expectedLengthDec = [NSDecimalNumber decimalNumberWithDecimal:length.decimalValue];
        }
      }
    
      if (headError || responseStatusCode != 200) {
        NSError *dataError;
        NSData *data;
        if (url) {
          data = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&dataError];
          if (data && !dataError) {
            NSNumber *length = [NSNumber numberWithUnsignedInteger:data.length];
            expectedLengthDec = [NSDecimalNumber decimalNumberWithDecimal:length.decimalValue];
          }
        }
      }
      
      NSMutableDictionary *spineItemDict = [[NSMutableDictionary alloc] init];
      if (expectedLengthDec) [spineItemDict setObject:expectedLengthDec forKey:@"spineItemBytesLength"];
      if (spineItem.baseHref) [spineItemDict setObject:spineItem.baseHref forKey:@"spineItemBaseHref"];
      if (spineItem.idref) [spineItemDict setObject:spineItem.idref forKey:@"spineItemIdref"];
      if (totalLength) [spineItemDict setObject:totalLength forKey:@"totalLengthSoFar"];

      NSString *title = [self titleForSpineItem:spineItem inTOC:self.package.tableOfContents.children];
      if (title && [[title class] isSubclassOfClass:[NSString class]]) {
        [spineItemDict setObject:title forKey:@"tocElementTitle"];
      }
      else {
        [spineItemDict setObject:NSLocalizedString(@"ReaderViewControllerCurrentChapter", nil) forKey:@"tocElementTitle"];
      }

      [bookDicts setObject:spineItemDict forKey:spineItem.idref];
      totalLength = [totalLength decimalNumberByAdding: expectedLengthDec];
    }
  }
  
  [bookDicts setObject:totalLength forKey:@"totalLength"];
  
  return bookDicts;
}

- (NSString *)titleForSpineItem:(RDSpineItem *)spineItem inTOC:(NSArray *)children {
  for (RDNavigationElement *child in children) {
    if ([child.content containsString:spineItem.baseHref]) {
      return child.title;
    }
  }
  return nil;
}

- (void)calculateProgressionWithDictionary:(NSDictionary *const)dictionary
                               withHandler:(void(^ const)(void))handler
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
  
  NSString *documentPath;
  if (@available(iOS 12.0, *)) {
    documentPath = @"window.frames[\"epubContentIframe\"].contentWindow.document";
  } else {
    documentPath = @"window.frames[\"epubContentIframe\"].document";
  }
  
  [self.webView
   evaluateJavaScript:[documentPath stringByAppendingString:@".readyState"]
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
  
  // A weak reference is needed here so that the main queue does not retain
  // `NYPLReaderReadiumView` indefinitely. After the reference to `weakSelf`
  // becomes nil, the block passed to `dispatch_after` will be called one
  // final time and will not be rescheduled (because `pollReadyState` will
  // be sent to nil).
  __weak NYPLReaderReadiumView *const weakSelf = self;
  dispatch_after(dispatchTime, dispatch_get_main_queue(), ^{
    [weakSelf pollReadyState];
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

#pragma mark NYPLReaderRenderer

- (NSArray *)bookmarkElements
{
  if(_bookmarkElements) return _bookmarkElements;
  
  // otherwise, grab the bookmarks from the registry
  _bookmarkElements = [[NYPLBookRegistry sharedRegistry]
                       readiumBookmarksForIdentifier:self.book.identifier];
  
  return _bookmarkElements;
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

- (void)gotoBookmark:(NYPLReadiumBookmark *)bookmark
{
  NSMutableDictionary *const dictionary = [NSMutableDictionary dictionary];
  
  dictionary[@"package"] = self.package.dictionary;
  dictionary[@"settings"] = [[NYPLReaderSettings sharedSettings] readiumSettingsRepresentation];
  
  dictionary[@"openPageRequest"] = @{@"idref": bookmark.idref, @"elementCfi": bookmark.contentCFI};
  
  NSData *data = NYPLJSONDataFromObject(dictionary);
    
  [self sequentiallyEvaluateJavaScript:
   [NSString stringWithFormat:@"ReadiumSDK.reader.openBook(%@)",
    [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]]];
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
