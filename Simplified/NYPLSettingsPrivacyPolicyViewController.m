#import "NYPLConfiguration.h"

#import "NYPLSettingsPrivacyPolicyViewController.h"

@interface NYPLSettingsPrivacyPolicyViewController () <UIWebViewDelegate>

@property (nonatomic) UIWebView *webView;

@end

@implementation NYPLSettingsPrivacyPolicyViewController

#pragma mark UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.title = NSLocalizedString(@"PrivacyPolicy", nil);
  
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
  
  self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
  self.webView.delegate = self;
  self.webView.autoresizingMask = (UIViewAutoresizingFlexibleHeight
                                   | UIViewAutoresizingFlexibleWidth);
  self.webView.backgroundColor = [NYPLConfiguration backgroundColor];
  
  [self.webView loadRequest:
   [NSURLRequest requestWithURL:
    [[NSBundle mainBundle]
     URLForResource:@"privacy-policy"
     withExtension:@"html"]]];
  
  [self.view addSubview:self.webView];
}

#pragma mark UIWebViewDelegate

- (BOOL)webView:(__unused UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *const)request
 navigationType:(UIWebViewNavigationType)navigationType
{
  if(navigationType == UIWebViewNavigationTypeLinkClicked) {
    [[UIApplication sharedApplication] openURL:request.URL];
    return NO;
  }
  
  return [request.URL.scheme isEqualToString:@"file"];
}

@end
