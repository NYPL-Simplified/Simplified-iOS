#import "NYPLConfiguration.h"
#import "NYPLSettings.h"

#import "NYPLSettingsEULAViewController.h"

@interface NYPLSettingsEULAViewController ()
@property (nonatomic) UIWebView *webView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;
@end

static NSString * const fallbackEULAURLString = @"http://www.librarysimplified.org/EULA.html";

@implementation NYPLSettingsEULAViewController

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.title = NSLocalizedString(@"EULA", nil);
  
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
  
  NSURL *url = [[NYPLSettings sharedSettings] eulaURL];
  NSURLRequest *const request = [NSURLRequest requestWithURL:url
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
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close"
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
                                                         NSURL *url = [[NYPLSettings sharedSettings] eulaURL];
                                                         NSURLRequest *const request = [NSURLRequest requestWithURL:url
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
