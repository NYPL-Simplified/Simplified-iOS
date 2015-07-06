#import "NYPLConfiguration.h"

#import "NYPLSettingsRegistrationViewController.h"

@interface NYPLSettingsRegistrationViewController () <UIScrollViewDelegate, UIWebViewDelegate>

@property (nonatomic) UIWebView *webView;

@end

@implementation NYPLSettingsRegistrationViewController

#pragma mark UIViewController

- (void)viewDidLoad
{  
  // This is the standard height of a UINavigationBar.
  static CGFloat const barHeight = 64.0;
  
  UINavigationBar *const bar = [[UINavigationBar alloc] init];
  bar.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), barHeight);
  bar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  
  UINavigationItem *const item = [[UINavigationItem alloc]
                                  initWithTitle:NSLocalizedString(@"SignUp", nil)];
  
  UIBarButtonItem *const cancelButton = [[UIBarButtonItem alloc]
                                         initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                         target:self
                                         action:@selector(didSelectCancel)];
  
  item.leftBarButtonItem = cancelButton;
  
  [bar pushNavigationItem:item animated:NO];
  
  [self.view addSubview:bar];
  
  self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
  self.webView.delegate = self;
  self.webView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                   UIViewAutoresizingFlexibleHeight);
  self.webView.backgroundColor = [NYPLConfiguration backgroundColor];
  self.webView.scrollView.bounces = NO;
  self.webView.scrollView.contentInset = UIEdgeInsetsMake(barHeight, 0, 0, 0);
  self.webView.scrollView.delegate = self;
  [self.view addSubview:self.webView];
  
  [self.view bringSubviewToFront:bar];
}

- (void)viewWillAppear:(__attribute__((unused)) BOOL)animated
{
  [self.webView loadRequest:[NSURLRequest requestWithURL:[NYPLConfiguration registrationURL]]];
}

#pragma mark UIWebViewDelegate

- (void)webViewDidFinishLoad:(__attribute__((unused)) UIWebView *)webView
{
  [self.webView stringByEvaluatingJavaScriptFromString:
   @"document.documentElement.style.webkitUserSelect = 'none';"];
  
  [self.webView stringByEvaluatingJavaScriptFromString:
   @"document.documentElement.style.webkitTouchCallout = 'none';"];
  
  [self.webView stringByEvaluatingJavaScriptFromString:
   @"document.body.ontouchend = function(e) {e.preventDefault();};"];
}

#pragma mark UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(__attribute__((unused)) UIScrollView *)scrollView
{
  return nil;
}

#pragma mark -

- (void)didSelectCancel
{
  [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
