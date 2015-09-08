#import "NYPLBook.h"
#import "NYPLBookLocation.h"
#import "NYPLBookRegistry.h"
#import "NYPLJSON.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLReaderContainerDelegate.h"
#import "NYPLReaderRenderer.h"
#import "NYPLReaderSettings.h"
#import "NYPLReaderTOCElement.h"
#import "NYPLReadium.h"
#import "UIColor+NYPLColorAdditions.h"
#import "NYPLLog.h"
#import "NYPLReaderReadiumView.h"
#import "UIColor+NYPLColorAdditions.h"
#import "NYPLConfiguration.h"

@interface NYPLReaderReadiumView ()
  <NYPLReaderRenderer, RDPackageResourceServerDelegate, UIScrollViewDelegate,
   UIWebViewDelegate>

@property (nonatomic) NYPLBook *book;
@property (nonatomic) BOOL bookIsCorrupt;
@property (nonatomic) RDContainer *container;
@property (nonatomic) NYPLReaderContainerDelegate *containerDelegate;
@property (nonatomic) BOOL loaded;
@property (nonatomic) BOOL mediaOverlayIsPlaying;
@property (nonatomic) NSInteger openPageCount;
@property (nonatomic) RDPackage *package;
@property (nonatomic) BOOL pageProgressionIsLTR;
@property (nonatomic) RDPackageResourceServer *server;
@property (nonatomic) NSArray *TOCElements;
@property (nonatomic) UIWebView *webView;

@property (nonatomic) NSDictionary *bookMapDictionary;
@property (nonatomic) NSNumber *spineItemPercentageRemaining;
@property (nonatomic) NSNumber *progressWithinBook;
@property (nonatomic) NSDictionary *spineItemDetails;

@end

static NSString *const renderer = @"readium";

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
  
  self.webView = [[UIWebView alloc] initWithFrame:self.bounds];
  self.webView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                   UIViewAutoresizingFlexibleWidth);
  self.webView.delegate = self;
  self.webView.scrollView.bounces = NO;
  self.webView.hidden = YES;
  self.webView.scrollView.delegate = self;
  [self addSubview:self.webView];
  
  NSURL *const readerURL = [[NSBundle mainBundle]
                            URLForResource:@"reader"
                            withExtension:@"html"];
  
  assert(readerURL);
  
  [self.webView loadRequest:[NSURLRequest requestWithURL:readerURL]];
  
  [self addObservers];
  
  self.backgroundColor = [NYPLReaderSettings sharedSettings].backgroundColor;
  
  [NYPLReaderSettings sharedSettings].currentReaderReadiumView = self;
  
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
    [self.webView stringByEvaluatingJavaScriptFromString: javaScript];
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
    [self.webView stringByEvaluatingJavaScriptFromString:javaScript];
    
    
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
    
    [self.webView stringByEvaluatingJavaScriptFromString:javascriptToChangeHighlightColour];
    
    self.webView.backgroundColor = [NYPLReaderSettings sharedSettings].backgroundColor;
  }];
}

- (void) applyMediaOverlayPlaybackToggle {
  
  NSString *isPlaying = [self.webView stringByEvaluatingJavaScriptFromString:
                  @"ReadiumSDK.reader.isPlayingMediaOverlay()"];
  
  NSString *isAvailable = [self.webView stringByEvaluatingJavaScriptFromString:
                    @"ReadiumSDK.reader.isMediaOverlayAvailable()"];
  
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    NSString *javaScript;
    if (isPlaying.length == 0 && [isAvailable containsString:@"true"]) {
      javaScript = [NSString stringWithFormat: @"ReadiumSDK.reader.playMediaOverlay()"];
      
      if(UIAccessibilityIsVoiceOverRunning())
      {
        self.webView.accessibilityElementsHidden = YES;
      }
    }
    else {
      javaScript = [NSString stringWithFormat: @"ReadiumSDK.reader.pauseMediaOverlay()"];
      
      if(UIAccessibilityIsVoiceOverRunning())
      {
        self.webView.accessibilityElementsHidden = NO;
      }
    }
    [self.webView stringByEvaluatingJavaScriptFromString:javaScript];
  }];
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
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [self.webView stringByEvaluatingJavaScriptFromString:javaScript];
  }];
}

#pragma mark UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(__attribute__((unused)) UIScrollView *)scrollView
{
  return nil;
}

#pragma mark UIWebViewDelegate

- (BOOL)
webView:(__attribute__((unused)) UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *const)request
navigationType:(__attribute__((unused)) UIWebViewNavigationType)navigationType
{
  if(self.bookIsCorrupt) {
    return NO;
  }
  
  if([request.URL.scheme isEqualToString:@"simplified"]) {
    NSArray *const components = [request.URL.resourceSpecifier componentsSeparatedByString:@"/"];
    NSString *const function = components[0];
    if([function isEqualToString:@"gesture-left"]) {
      [self.webView stringByEvaluatingJavaScriptFromString:@"ReadiumSDK.reader.openPageLeft()"];
    } else if([function isEqualToString:@"gesture-right"]) {
      [self.webView stringByEvaluatingJavaScriptFromString:@"ReadiumSDK.reader.openPageRight()"];
    } else if([function isEqualToString:@"gesture-center"]) {
      [self.delegate renderer:self didReceiveGesture:NYPLReaderRendererGestureToggleUserInterface];
    } else {
      NYPLLOG(@"Ignoring unknown simplified function.");
    }
    
    if ([function containsString:@"gesture"]) {
      [self.delegate rendererDidRegisterGesture:self];
    }
    return NO;
  }
  
  if([request.URL.scheme isEqualToString:@"readium"]) {
    NSArray *const components = [request.URL.resourceSpecifier componentsSeparatedByString:@"/"];
    NSString *const function = components[0];
    if([function isEqualToString:@"initialize"]) {
      [self readiumInitialize];
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
    return NO;
  }
  
  return YES;
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
  
  [self.webView stringByEvaluatingJavaScriptFromString:
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
  
  [self.webView stringByEvaluatingJavaScriptFromString: javascript];
}

- (void)readiumPaginationChangedWithDictionary:(NSDictionary *const)dictionary
{
  // If the book is finished opening, set all stylistic preferences.
  if(!self.loaded) {
    [self applyCurrentFlowDependentSettings];
    [self applyCurrentFlowIndependentSettings];
    self.loaded = YES;
    [self.delegate rendererDidFinishLoading:self];
  }
  
  [self.webView stringByEvaluatingJavaScriptFromString:@"simplified.pageDidChange();"];
  
  // Use left-to-right unless it explicitly asks for right-to-left.
  self.pageProgressionIsLTR = ![dictionary[@"pageProgressionDirection"]
                                isEqualToString:@"rtl"];
  
  NSArray *const openPages = dictionary[@"openPages"];
  
  self.openPageCount = openPages.count;
  
  NSString *const locationJSON = [self.webView stringByEvaluatingJavaScriptFromString:
                                  @"ReadiumSDK.reader.bookmarkCurrentPage()"];
  
  NYPLBookLocation *const location = [[NYPLBookLocation alloc]
                                      initWithLocationString:locationJSON
                                      renderer:renderer];
  
  [self calculateProgressionWithDictionary:dictionary withHandler:^(void) {
    [self.delegate didUpdateProgressSpineItemPercentage:self.spineItemPercentageRemaining bookPercentage:self.progressWithinBook withCurrentSpineItemDetails:self.spineItemDetails];
  }];
  
  if(location) {
    [[NYPLBookRegistry sharedRegistry]
     setLocation:location
     forIdentifier:self.book.identifier];
  }
  
  self.webView.hidden = NO;
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

- (void)calculateProgressionWithDictionary:(NSDictionary *const)dictionary withHandler:(void(^)(void))handler {
  if (!self.bookMapDictionary) return;
  
  NSArray *openPagesArray = [dictionary objectForKey:@"openPages"];
  NSDictionary *openPagesDict = [openPagesArray firstObject];
  
  NSDecimalNumberHandler *numberHandler = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundUp scale:0 raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:NO];
  
  NSString *spineItemIdref = [openPagesDict objectForKey:@"idref"];
  
  NSNumber *spineItemPageCount = [openPagesDict objectForKey:@"spineItemPageCount"];
  NSDecimalNumber *spineItemPageCountDec = [NSDecimalNumber decimalNumberWithDecimal:spineItemPageCount.decimalValue];
  
  NSNumber *spineItemPageIndex = [openPagesDict objectForKey:@"spineItemPageIndex"];
  NSDecimalNumber *spineItemPageIndexDec = [NSDecimalNumber decimalNumberWithDecimal:spineItemPageIndex.decimalValue];
  
  NSDecimalNumber *progressWithinSpineDec = [[spineItemPageIndexDec decimalNumberByDividingBy:spineItemPageCountDec] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"100"] withBehavior:numberHandler];
  
  NSDecimalNumber *decimal100 = [NSDecimalNumber decimalNumberWithString:@"100"];
  NSDecimalNumber *spineItemPercentageRemaining = [decimal100 decimalNumberBySubtracting:progressWithinSpineDec];
  NSDecimalNumber *progressWithinSpineUnmodifiedDec = [spineItemPageIndexDec decimalNumberByDividingBy:spineItemPageCountDec];
  
  NSDictionary *spineItemDetails = [self.bookMapDictionary objectForKey:spineItemIdref];
  
  NSNumber *spineItemLength = [spineItemDetails objectForKey:@"spineItemBytesLength"];
  NSDecimalNumber *spineItemLengthDec = [NSDecimalNumber decimalNumberWithDecimal:spineItemLength.decimalValue];
  
  NSNumber *totalLengthSoFar = [spineItemDetails objectForKey:@"totalLengthSoFar"];
  NSDecimalNumber *totalLengthSoFarDec = [NSDecimalNumber decimalNumberWithDecimal:totalLengthSoFar.decimalValue];
  
  NSNumber *totalLength = [self.bookMapDictionary objectForKey:@"totalLength"];
  NSDecimalNumber *totalLengthDec = [NSDecimalNumber decimalNumberWithDecimal:totalLength.decimalValue];
  
  NSDecimalNumber *partialLengthProgressedInSpineDec = [spineItemLengthDec decimalNumberByMultiplyingBy:progressWithinSpineUnmodifiedDec withBehavior:numberHandler];
  NSDecimalNumber *totalProgressSoFarDec = [partialLengthProgressedInSpineDec decimalNumberByAdding:totalLengthSoFarDec withBehavior:numberHandler];
  
  NSDecimalNumber *totalProgressSoFarPercentageDec = totalLength.floatValue > 0 ? [[totalProgressSoFarDec decimalNumberByDividingBy:totalLengthDec] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"100"] withBehavior:numberHandler] : [NSDecimalNumber zero];
  
  self.spineItemPercentageRemaining = spineItemPercentageRemaining;
  self.progressWithinBook = totalProgressSoFarPercentageDec;
  self.spineItemDetails = spineItemDetails;
  
  if (handler) handler();
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
  
  [self.webView stringByEvaluatingJavaScriptFromString:
   [NSString stringWithFormat:@"ReadiumSDK.reader.openContentUrl('%@', '%@')",
    navigationElement.content,
    navigationElement.sourceHref]];
}

- (BOOL) bookHasMediaOverlays {
  NSString *isAvailable = [self.webView stringByEvaluatingJavaScriptFromString:
                           @"ReadiumSDK.reader.isMediaOverlayAvailable()"];
  if ( [isAvailable containsString:@"true"]) {
    return YES;
  }
  else {
    return NO;
  }
}

- (BOOL) bookHasMediaOverlaysBeingPlayed {
  
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
}

@end
