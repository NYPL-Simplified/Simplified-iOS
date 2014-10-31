#import "NSString+NYPLStringAdditions.h"
#import "NYPLBook.h"
#import "NYPLBookLocation.h"
#import "NYPLConfiguration.h"
#import "NYPLJSON.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLMyBooksRegistry.h"
#import "NYPLReaderTOCViewController.h"
#import "NYPLReadium.h"

#import "NYPLReaderViewController.h"

@interface NYPLReaderViewController ()
  <NYPLReaderTOCViewControllerDelegate, RDContainerDelegate, RDPackageResourceServerDelegate,
   UIPopoverControllerDelegate, UIScrollViewDelegate, UIWebViewDelegate>

@property (nonatomic) UIPopoverController *activePopoverController;
@property (nonatomic) BOOL bookIsCorrupted;
@property (nonatomic) NSString *bookIdentifier;
@property (nonatomic) RDContainer *container;
@property (nonatomic) BOOL interfaceHidden;
@property (nonatomic) BOOL mediaOverlayIsPlaying;
@property (nonatomic) NSInteger openPageCount;
@property (nonatomic) NSInteger pageInCurrentSpineItemCount;
@property (nonatomic) NSInteger pageInCurrentSpineItemIndex;
@property (nonatomic) BOOL pageProgressionIsLTR;
@property (nonatomic) RDPackage *package;
@property (nonatomic) RDPackageResourceServer *server;
@property (nonatomic) BOOL shouldHideInterfaceOnNextAppearance;
@property (nonatomic) NSInteger spineItemIndex;
@property (nonatomic) UIWebView *webView;

@end

id argument(NSURL *const URL) {
  NSString *const s = URL.resourceSpecifier;
  
  NSRange const range = [s rangeOfString:@"/"];
  
  assert(range.location != NSNotFound);
  
  NSData *const data = [[[s substringFromIndex:(range.location + 1)]
                         stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                        dataUsingEncoding:NSUTF8StringEncoding];
  
  return NYPLJSONObjectFromData(data);
}

@implementation NYPLReaderViewController

#pragma mark NSObject

- (instancetype)initWithBookIdentifier:(NSString *const)bookIdentifier
{
  self = [super init];
  if(!self) return nil;
  
  if(!bookIdentifier) {
    @throw NSInvalidArgumentException;
  }
  
  self.title = [[NYPLMyBooksRegistry sharedRegistry]
                bookForIdentifier:bookIdentifier].title;
  
  self.bookIdentifier = bookIdentifier;
  
  @try {
    self.container = [[RDContainer alloc]
                      initWithDelegate:self
                      path:[[[NYPLMyBooksDownloadCenter sharedDownloadCenter]
                        fileURLForBookIndentifier:bookIdentifier]
                            path]];
  } @catch (...) {
    self.bookIsCorrupted = YES;
    [[[UIAlertView alloc]
      initWithTitle:NSLocalizedString(@"ReaderViewControllerCorruptedTitle", nil)
      message:NSLocalizedString(@"ReaderViewControllerCorruptedMessage", nil)
      delegate:nil
      cancelButtonTitle:nil
      otherButtonTitles:NSLocalizedString(@"OK", nil), nil]
     show];
  }
  
  self.package = self.container.firstPackage;
  self.server = [[RDPackageResourceServer alloc]
                 initWithDelegate:self
                 package:self.package
                 specialPayloadAnnotationsCSS:nil
                 specialPayloadMathJaxJS:nil];

  self.hidesBottomBarWhenPushed = YES;
  
  [[NYPLMyBooksRegistry sharedRegistry]
   setState:NYPLMYBooksStateUsed
   forIdentifier:bookIdentifier];
  
  return self;
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.automaticallyAdjustsScrollViewInsets = NO;

  self.shouldHideInterfaceOnNextAppearance = YES;
  
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
  
  UIBarButtonItem *const TOCButtonItem = [[UIBarButtonItem alloc]
                                          initWithImage:[UIImage imageNamed:@"TOC"]
                                          style:UIBarButtonItemStylePlain
                                          target:self
                                          action:@selector(didSelectTOC)];
  
  self.navigationItem.rightBarButtonItems = @[TOCButtonItem];
  
  self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
  self.webView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                   UIViewAutoresizingFlexibleWidth);
  self.webView.backgroundColor = [UIColor whiteColor];
  self.webView.delegate = self;
  self.webView.scrollView.bounces = NO;
  self.webView.hidden = YES;
  self.webView.scrollView.delegate = self;
  [self.view addSubview:self.webView];
  
  NSURL *const readerURL = [[NSBundle mainBundle]
                            URLForResource:@"reader"
                            withExtension:@"html"];
  
  assert(readerURL);
  
  [self.webView loadRequest:[NSURLRequest requestWithURL:readerURL]];
}

- (BOOL)prefersStatusBarHidden
{
  return self.interfaceHidden;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
  return UIStatusBarAnimationNone;
}

- (void)viewDidAppear:(__attribute__((unused)) BOOL)animated
{
  if(self.shouldHideInterfaceOnNextAppearance) {
    self.shouldHideInterfaceOnNextAppearance = NO;
    self.interfaceHidden = YES;
  }
}

#pragma mark UIWebViewDelegate

- (BOOL)
webView:(__attribute__((unused)) UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *const)request
navigationType:(__attribute__((unused)) UIWebViewNavigationType)navigationType
{
  if(self.bookIsCorrupted) {
    return NO;
  }
  
  if(!([request.URL.scheme isEqualToString:@"readium"] ||
       [request.URL.scheme isEqualToString:@"simplified"])) {
    return YES;
  }
  
  NSArray *const components = [request.URL.resourceSpecifier componentsSeparatedByString:@"/"];
  assert([components count] >= 1);
  
  NSString *const function = components[0];
  
  // FIXME: Factor out simplified and readium handling into separate methods.
  if([request.URL.scheme isEqualToString:@"simplified"]) {
    if([function isEqualToString:@"gesture-left"]) {
      [self.webView stringByEvaluatingJavaScriptFromString:@"ReadiumSDK.reader.openPageLeft()"];
    } else if([function isEqualToString:@"gesture-right"]) {
      [self.webView stringByEvaluatingJavaScriptFromString:@"ReadiumSDK.reader.openPageRight()"];
    } else if([function isEqualToString:@"gesture-center"]) {
      self.interfaceHidden = !self.interfaceHidden;
    } else {
      NYPLLOG(@"Ignoring unknown simplified function.");
    }
    return NO;
  }
  
  if([function isEqualToString:@"initialize"]) {    
    if(!self.package.spineItems[0]) {
      self.bookIsCorrupted = YES;
      [[[UIAlertView alloc]
        initWithTitle:NSLocalizedString(@"ReaderViewControllerCorruptedTitle", nil)
        message:NSLocalizedString(@"ReaderViewControllerCorruptedMessage", nil)
        delegate:nil
        cancelButtonTitle:nil
        otherButtonTitles:NSLocalizedString(@"OK", nil), nil]
       show];
      return NO;
    }
    
    self.package.rootURL = [NSString stringWithFormat:@"http://127.0.0.1:%d/", self.server.port];
    
    NSString *const syntheticSpread = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad
                                       ? @"double"
                                       : @"single");
    
    NSDictionary *const settingsDictionary = @{@"columnGap": @20,
                                               @"fontSize": @100,
                                               @"scroll": @"fixed",
                                               @"syntheticSpread": syntheticSpread};

    NYPLBookLocation *const location = [[NYPLMyBooksRegistry sharedRegistry]
                                        locationForIdentifier:self.bookIdentifier];
    
    NSMutableDictionary *const dictionary = [NSMutableDictionary dictionary];
    dictionary[@"package"] = self.package.dictionary;
    dictionary[@"settings"] = settingsDictionary;
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
      return NO;
    }
    
    [self.webView stringByEvaluatingJavaScriptFromString:
     [NSString stringWithFormat:@"ReadiumSDK.reader.openBook(%@)",
      [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]]];
    
    return NO;
  }
  
  if([function isEqualToString:@"pagination-changed"]) {
    [self.webView stringByEvaluatingJavaScriptFromString:@"simplified.pageDidChange();"];
    
    NSDictionary *const dictionary = argument(request.URL);
    
    // Use left-to-right unless it explicitly asks for right-to-left.
    self.pageProgressionIsLTR = ![[dictionary objectForKey:@"pageProgressionDirection"]
                                  isEqualToString:@"rtl"];
    
    NSArray *const openPages = [dictionary objectForKey:@"openPages"];
    
    self.openPageCount = openPages.count;
    
    if(self.openPageCount >= 1) {
      NSDictionary *const page = openPages[0];
      self.pageInCurrentSpineItemCount =
        ((NSNumber *)[page objectForKey:@"spineItemPageCount"]).integerValue;
      self.pageInCurrentSpineItemIndex =
        ((NSNumber *)[page objectForKey:@"spineItemPageIndex"]).integerValue;
      self.spineItemIndex = ((NSNumber *)[page objectForKey:@"spineItemIndex"]).integerValue;
    }
    
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
       forIdentifier:self.bookIdentifier];
    }
    
    self.webView.hidden = NO;
    
    return NO;
  }
  
  if([function isEqualToString:@"media-overlay-status-changed"]) {
    NSDictionary *const dict = argument(request.URL);
    self.mediaOverlayIsPlaying = ((NSNumber *)[dict objectForKey:@"isPlaying"]).boolValue;
    
    return NO;
  }
  
  return NO;
}

#pragma mark UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
  assert(popoverController == self.activePopoverController);
  
  self.activePopoverController = nil;
}

#pragma mark UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(__attribute__((unused)) UIScrollView *)scrollView
{
  return nil;
}

#pragma mark NYPLReaderTOCViewControllerDelegate

- (void)TOCViewController:(__attribute__((unused)) NYPLReaderTOCViewController *)controller
didSelectNavigationElement:(RDNavigationElement *)navigationElement
{
  [self.webView stringByEvaluatingJavaScriptFromString:
   [NSString stringWithFormat:@"ReadiumSDK.reader.openContentUrl('%@', '%@')",
    navigationElement.content,
    navigationElement.sourceHref]];
  
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    [self.activePopoverController dismissPopoverAnimated:YES];
    self.interfaceHidden = YES;
  } else {
    self.shouldHideInterfaceOnNextAppearance = YES;
    [self.navigationController popViewControllerAnimated:YES];
  }
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

#pragma mark -

- (void)didSelectTOC
{
  NYPLReaderTOCViewController *const viewController =
    [[NYPLReaderTOCViewController alloc] initWithNavigationElement:self.package.tableOfContents];
  
  viewController.delegate = self;
  
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    self.activePopoverController =
      [[UIPopoverController alloc] initWithContentViewController:viewController];
    self.activePopoverController.delegate = self;
    [self.activePopoverController
     presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem
     permittedArrowDirections:UIPopoverArrowDirectionUp
     animated:YES];
  } else {
    [self.navigationController pushViewController:viewController animated:YES];
  }
}

- (void)setInterfaceHidden:(BOOL)interfaceHidden
{
  _interfaceHidden = interfaceHidden;

  self.navigationController.interactivePopGestureRecognizer.enabled = !interfaceHidden;
  
  self.navigationController.navigationBarHidden = self.interfaceHidden;
  
  [self setNeedsStatusBarAppearanceUpdate];
}
  
@end
