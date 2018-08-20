#import "NYPLConfiguration.h"
#import "NYPLSettings.h"

#import "NYPLSettingsEULAViewController.h"

@interface NYPLSettingsEULAViewController ()
@property (nonatomic) UIWebView *webView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic) NSURL *eulaURL;

@end

@implementation NYPLSettingsEULAViewController

- (instancetype)initWithAccount:(Account *)account
{
  self = [super init];
  if(!self) return nil;
  
  self.title = NSLocalizedString(@"EULA", nil);
  self.eulaURL = [account getLicenseURL:URLTypeEula];
  
  return self;
}

- (instancetype)initWithNYPLURL
{
  self = [super init];
  if(!self) return nil;
  
  self.title = NSLocalizedString(@"EULA", nil);
  self.eulaURL = [NSURL URLWithString:NYPLUserAgreementURLString];
  
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
  
  self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
  self.webView.autoresizingMask = (UIViewAutoresizingFlexibleHeight
                                   | UIViewAutoresizingFlexibleWidth);
  self.webView.backgroundColor = [NYPLConfiguration backgroundColor];
  self.webView.delegate = self;
  
  NSURLRequest *const request = [NSURLRequest requestWithURL:self.eulaURL
                                                 cachePolicy:NSURLRequestUseProtocolCachePolicy
                                             timeoutInterval:15.0];
  
  [self.webView loadRequest:request];
  [self.view addSubview:self.webView];
  
  self.activityIndicatorView =
  [[UIActivityIndicatorView alloc]
   initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  self.activityIndicatorView.center = self.view.center;
  self.activityIndicatorView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                                 UIViewAutoresizingFlexibleHeight);
  [self.activityIndicatorView startAnimating];
  [self.view addSubview:self.activityIndicatorView];
  
  if ( self == [self.navigationController.viewControllers objectAtIndex:0] ) {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil)
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(dismissEULA)];
  }
}

- (void)dismissEULA
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark NSURLConnectionDelegate
- (void)webView:(__attribute__((unused)) UIWebView *)webView didFailLoadWithError:(__attribute__((unused)) NSError *)error {
  [self.activityIndicatorView stopAnimating];
  
  UIAlertController *alertController = [UIAlertController
                                        alertControllerWithTitle:NSLocalizedString(@"ConnectionFailed", nil)
                                        message:NSLocalizedString(@"ConnectionFailedDescription", nil)
                                        preferredStyle:UIAlertControllerStyleAlert];
  
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                         style:UIAlertActionStyleDestructive
                                                       handler:^(UIAlertAction *cancelAction) {
                                                         if (cancelAction) {
                                                           [self.navigationController popViewControllerAnimated:YES];
                                                         }
                                                       }];
  
  UIAlertAction *reloadAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Reload", nil)
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *reloadAction) {
                                                       if (reloadAction) {
                                                         NSURLRequest *const request = [NSURLRequest requestWithURL:self.eulaURL
                                                                                                        cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                                                                    timeoutInterval:15.0];
                                                         
                                                         [self.webView loadRequest:request];
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
}

@end
