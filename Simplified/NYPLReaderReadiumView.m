#import "NYPLBook.h"
#import "NYPLBookLocation.h"
#import "NYPLBookRegistry.h"
#import "NYPLJSON.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLReaderRenderer.h"
#import "NYPLReaderSettings.h"
#import "NYPLReaderTOCElement.h"
#import "NYPLReadium.h"
#import "UIColor+NYPLColorAdditions.h"

#import "NYPLReaderReadiumView.h"

@interface NYPLReaderReadiumView ()
  <NYPLReaderRenderer, RDContainerDelegate, RDPackageResourceServerDelegate, UIScrollViewDelegate,
   UIWebViewDelegate>

@property (nonatomic) NYPLBook *book;
@property (nonatomic) BOOL bookIsCorrupt;
@property (nonatomic) RDContainer *container;
@property (nonatomic) BOOL loaded;
@property (nonatomic) BOOL mediaOverlayIsPlaying;
@property (nonatomic) NSInteger openPageCount;
@property (nonatomic) RDPackage *package;
@property (nonatomic) BOOL pageProgressionIsLTR;
@property (nonatomic) RDPackageResourceServer *server;
@property (nonatomic) NSArray *TOCElements;
@property (nonatomic) UIWebView *webView;

@property (nonatomic) NSDictionary *bookMapDictionary;
@property (nonatomic) NSNumber *progressWithinSpine;
@property (nonatomic) NSNumber *progressWithinBook;

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
  
  self.delegate = delegate;
  
  @try {
    self.container = [[RDContainer alloc]
                      initWithDelegate:self
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
}

- (void)applyCurrentFlowDependentSettings
{
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [self.webView stringByEvaluatingJavaScriptFromString:
     [NSString stringWithFormat:
      @"ReadiumSDK.reader.updateSettings(%@)",
      [[NSString alloc]
       initWithData:NYPLJSONDataFromObject([[NYPLReaderSettings sharedSettings]
                                            readiumSettingsRepresentation])
       encoding:NSUTF8StringEncoding]]];
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
    
    self.webView.backgroundColor = [NYPLReaderSettings sharedSettings].backgroundColor;
  }];
}

#pragma mark NSObject

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark RDContainerDelegate

- (BOOL)container:(__attribute__((unused)) RDContainer *)container
   handleSdkError:(NSString * const)message
isSevereEpubError:(const BOOL)isSevereEpubError
{
  NYPLLOG_F(@"(Readium) %@ %@", isSevereEpubError ? @"(SEVERE)" : @"", message);

  // Ignore the error and continue.
  return YES;
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
    } else if([function isEqualToString:@"settings-applied"]) {
      // Do nothing.
    } else {
      NYPLLOG(@"Ignoring unknown readium function.");
    }
    return NO;
  }
  
  return YES;
}

#pragma mark -

- (void)readiumInitialize
{
  if(!self.package.spineItems[0]) {
    self.bookIsCorrupt = YES;
    [self.delegate renderer:self didEncounterCorruptionForBook:self.book];
    return;
  }
  
  self.package.rootURL = [NSString stringWithFormat:@"http://127.0.0.1:%d/", self.server.port];
  [self calculateBookLength];
  
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
    dictionary[@"openPageRequest"] = @{@"idref": locationDictionary[@"idref"],
                                       @"elementCfi": locationDictionary[@"contentCFI"]};
  }
  
  NSData *data = NYPLJSONDataFromObject(dictionary);
  
  if(!data) {
    NYPLLOG(@"Failed to construct 'openBook' call.");
    return;
  }
  
  [self.webView stringByEvaluatingJavaScriptFromString:
   [NSString stringWithFormat:@"ReadiumSDK.reader.openBook(%@)",
    [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]]];
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
  
  NSDictionary *openPagesDict = [openPages firstObject];
  NSNumber *spineItemIndex = [openPagesDict objectForKey:@"spineItemIndex"];
  NSNumber *spineItemIndexPlus1 = [NSNumber numberWithInt:(spineItemIndex.intValue + 1)];
  
  [self calculateProgressionWithDictionary:dictionary withHandler:^(void) {
    [self.delegate didUpdateProgressWithinSpineTo:self.progressWithinSpine withinBookTo:self.progressWithinBook withSpineID:spineItemIndexPlus1];
  }];
  
  if(location) {
    [[NYPLBookRegistry sharedRegistry]
     setLocation:location
     forIdentifier:self.book.identifier];
  }
  
  self.webView.hidden = NO;
}

- (void) calculateBookLength {
  NSDecimalNumber *totalLength = [[NSDecimalNumber alloc] initWithInt:0];
  
  NSMutableDictionary *bookDicts = [[NSMutableDictionary alloc] init];
  
  for (RDSpineItem *spineItem in self.package.spineItems) {
    if ([spineItem.mediaType isEqualToString:@"application/xhtml+xml"]) {
      NSURL *file =[NSURL URLWithString:[self.server.package.rootURL stringByAppendingPathComponent:spineItem.baseHref]];
      NSData *data = [NSData dataWithContentsOfURL:file];
      NSMutableDictionary *spineItemDict = [[NSMutableDictionary alloc] init];
      [spineItemDict setObject:[NSNumber numberWithUnsignedInteger:data.length] forKey:@"spineItemBytesLength"];
      [spineItemDict setObject:spineItem.baseHref forKey:@"spineItemBaseHref"];
      [spineItemDict setObject:spineItem.idref forKey:@"spineItemIdref"];
      [spineItemDict setObject:totalLength forKey:@"totalLengthSoFar"];
      [bookDicts setObject:spineItemDict forKey:spineItem.idref];
      
      NSDecimalNumber *dataLength = [[NSDecimalNumber alloc] initWithUnsignedInteger:data.length];
      totalLength = [totalLength decimalNumberByAdding:dataLength];
    }
  }
  
  [bookDicts setObject:totalLength forKey:@"totalLength"];
  
  self.bookMapDictionary = bookDicts;
}

-(void) calculateProgressionWithDictionary:(NSDictionary *const)dictionary withHandler:(void(^)(void))handler {
  NSArray *openPagesArray = [dictionary objectForKey:@"openPages"];
  NSDictionary *openPagesDict = [openPagesArray firstObject];
  
  NSDecimalNumberHandler *numberHandler = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundUp scale:0 raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:NO];
  
  NSString *spineItemIdref = [openPagesDict objectForKey:@"idref"];
  
  NSNumber *spineItemPageCount = [openPagesDict objectForKey:@"spineItemPageCount"];
  NSDecimalNumber *spineItemPageCountDec = [NSDecimalNumber decimalNumberWithDecimal:spineItemPageCount.decimalValue];
  
  NSNumber *spineItemPageIndex = [openPagesDict objectForKey:@"spineItemPageIndex"];
  NSDecimalNumber *spineItemPageIndexDec = [NSDecimalNumber decimalNumberWithDecimal:spineItemPageIndex.decimalValue];
  
  NSDecimalNumber *progressWithinSpineDec = [[spineItemPageIndexDec decimalNumberByDividingBy:spineItemPageCountDec] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"100"] withBehavior:numberHandler ];
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
  
  NSDecimalNumber *totalProgressSoFarPercentageDec = [[totalProgressSoFarDec decimalNumberByDividingBy:totalLengthDec] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"100"] withBehavior:numberHandler ];
  
  self.progressWithinSpine = progressWithinSpineDec;
  self.progressWithinBook = totalProgressSoFarPercentageDec;
  
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


@end
