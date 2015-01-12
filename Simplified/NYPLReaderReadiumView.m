#import "NYPLBook.h"
#import "NYPLBookLocation.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLMyBooksRegistry.h"
#import "NYPLJSON.h"
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

@end

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

void generateTOCElements(NSArray *const navigationElements,
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
  [self.webView stringByEvaluatingJavaScriptFromString:
   [NSString stringWithFormat:
    @"ReadiumSDK.reader.updateSettings(%@)",
    [[NSString alloc]
     initWithData:NYPLJSONDataFromObject([[NYPLReaderSettings sharedSettings]
                                          readiumSettingsRepresentation])
     encoding:NSUTF8StringEncoding]]];
}

- (void)applyCurrentFlowIndependentSettings
{
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
}

#pragma mark NSObject

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark RDContainerDelegate

- (void)rdcontainer:(__attribute__((unused)) RDContainer *)container
     handleSdkError:(NSString *const)message
{
  NYPLLOG_F(@"Readium: %@", message);
}

#pragma mark RDPackageResourceServerDelegate

- (void)
rdpackageResourceServer:(__attribute__((unused)) RDPackageResourceServer *)packageResourceServer
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
  
  NYPLBookLocation *const location = [[NYPLMyBooksRegistry sharedRegistry]
                                      locationForIdentifier:self.book.identifier];
  
  NSMutableDictionary *const dictionary = [NSMutableDictionary dictionary];
  dictionary[@"package"] = self.package.dictionary;
  dictionary[@"settings"] = [[NYPLReaderSettings sharedSettings] readiumSettingsRepresentation];
  if(location) {
    if(location.CFI) {
      dictionary[@"openPageRequest"] = @{@"idref": location.idref, @"elementCfi" : location.CFI};
    } else {
      dictionary[@"openPageRequest"] = @{@"idref": location.idref};
    }
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
  
  NSDictionary *const locationDictionary =
  NYPLJSONObjectFromData([locationJSON dataUsingEncoding:NSUTF8StringEncoding]);
  
  NYPLBookLocation *const location = [[NYPLBookLocation alloc]
                                      initWithCFI:locationDictionary[@"contentCFI"]
                                      idref:locationDictionary[@"idref"]];
  
  if(location) {
    [[NYPLMyBooksRegistry sharedRegistry]
     setLocation:location
     forIdentifier:self.book.identifier];
  }
  
  self.webView.hidden = NO;
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
