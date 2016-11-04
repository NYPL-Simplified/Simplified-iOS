#import "NYPLConfiguration.h"
#import "NYPLSettings.h"

#import "NYPLSettingsPrivacyPolicyViewController.h"

@interface NYPLSettingsPrivacyPolicyViewController ()

@property (nonatomic) UIWebView *webView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;

@end

static NSString * const fallbackPrivacyURLString = @"http://www.librarysimplified.org/privacypolicy.html";

@implementation NYPLSettingsPrivacyPolicyViewController

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.title = NSLocalizedString(@"PrivacyPolicy", nil);
  
  return self;
}

#pragma mark UIViewController
- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
  
  self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
  self.webView.autoresizingMask = (UIViewAutoresizingFlexibleHeight
                                   | UIViewAutoresizingFlexibleWidth);
  self.webView.backgroundColor = [NYPLConfiguration backgroundColor];
  self.webView.delegate = self;
  
  NSURL *url = [[NYPLSettings sharedSettings] privacyPolicyURL];
  if (!url) {
    url = [NSURL URLWithString:fallbackPrivacyURLString];
  }
  
  
  NSURLRequest *const request = [NSURLRequest requestWithURL:url
                                                 cachePolicy:NSURLRequestUseProtocolCachePolicy
                                             timeoutInterval:15.0];
  
  [self.webView loadRequest:
   request];
  [self.view addSubview:self.webView];
  
  self.activityIndicatorView =
  [[UIActivityIndicatorView alloc]
   initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  self.activityIndicatorView.center = self.view.center;
  self.activityIndicatorView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                                 UIViewAutoresizingFlexibleHeight);
  [self.activityIndicatorView startAnimating];
  [self.view addSubview:self.activityIndicatorView];
}

- (void)loadLocalURLFromRequest:(NSURLRequest *)request
{
  NSURL *localURL = [[NSBundle mainBundle] URLForResource:@"privacy-policy" withExtension:@"html"];
  if ([[request URL] isEqual:localURL] == NO) {
    [self.webView loadRequest:[NSURLRequest requestWithURL:localURL]];
  }
}

#pragma mark NSURLConnectionDelegate
- (void)webView:(__attribute__((unused)) UIWebView *)webView didFailLoadWithError:(__attribute__((unused)) NSError *)error {
  [self.activityIndicatorView stopAnimating];
  
  // Try local URL if remote URL has failed
  [self loadLocalURLFromRequest: [webView request]];
  
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"ConnectionFailed", nil)
                                                                           message:NSLocalizedString(@"ConnectionFailed", nil)
                                                                    preferredStyle:UIAlertControllerStyleAlert];
  
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                         style:UIAlertActionStyleDestructive
                                                       handler:nil];
  
  UIAlertAction *reloadAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Reload", nil)
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *reloadAction) {
                                                         if (reloadAction) {
                                                           NSURL *url = [[NYPLSettings sharedSettings] privacyPolicyURL];
                                                           if (!url) {
                                                             url = [NSURL URLWithString:fallbackPrivacyURLString];
                                                           }
                                                           
                                                           NSURLRequest *const request = [NSURLRequest requestWithURL:url
                                                                                                          cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                                                                      timeoutInterval:15.0];
                                                           
                                                           [self.webView loadRequest:
                                                            request];
                                                         }
                                                       }];
  
  [alertController addAction:reloadAction];
  [alertController addAction:cancelAction];
  [self presentViewController:alertController
                     animated:NO
                   completion:nil];
}

- (void)webViewDidFinishLoad:(__attribute__((unused)) UIWebView *)webView {
  [self.activityIndicatorView stopAnimating];
  
  NSCachedURLResponse *urlResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:webView.request];
  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*) urlResponse.response;
  NSInteger statusCode = httpResponse.statusCode;
  if (statusCode > 399) {
    [self loadLocalURLFromRequest:[webView request]];
  }
}

@end
