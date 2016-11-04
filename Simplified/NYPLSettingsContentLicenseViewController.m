#import "NYPLConfiguration.h"
#import "NYPLSettings.h"

#import "NYPLSettingsContentLicenseViewController.h"

@interface NYPLSettingsContentLicenseViewController ()

@property (nonatomic) UIWebView *webView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;

@end

static NSString * const fallbackContentLicenseURLString = @"http://www.librarysimplified.org/contentlicense.html";

@implementation NYPLSettingsContentLicenseViewController

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.title = NSLocalizedString(@"ContentLicenses", nil);
  
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
  
  NSURL *url = [[NYPLSettings sharedSettings] contentLicenseURL];
  if (!url) {
    url = [NSURL URLWithString:fallbackContentLicenseURLString];
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

#pragma mark NSURLConnectionDelegate
- (void)webView:(__attribute__((unused)) UIWebView *)webView didFailLoadWithError:(__attribute__((unused)) NSError *)error {
  [self.activityIndicatorView stopAnimating];
  
  // Failed to load remote URL
  NSURL *localURL = [[NSBundle mainBundle] URLForResource:@"content-license" withExtension:@"html"];
  if ([[[webView request] URL] isEqual:localURL] == NO) {
    [self.webView loadRequest:[NSURLRequest requestWithURL:localURL]];
    return;
  }
  
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
                                                             url = [NSURL URLWithString:fallbackContentLicenseURLString];
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

-(void)webViewDidFinishLoad:(__attribute__((unused)) UIWebView *)webView {
  [self.activityIndicatorView stopAnimating];
}

@end
