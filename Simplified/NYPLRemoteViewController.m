#import "NYPLConfiguration.h"
#import "NYPLReloadView.h"
#import "NYPLRemoteViewController.h"
#import "NYPLSession.h"
#import "NYPLSettingsAccountViewController.h"
#import "NYPLAppDelegate.h"
#import "UIView+NYPLViewAdditions.h"
#import "NYPLAlertController.h"
#import "NYPLProblemDocument.h"
#import "NYPLSession.h"
#import "NYPLAccount.h"
#import "NYPLSettingsAccountViewController.h"

@interface NYPLRemoteViewController () <NSURLConnectionDataDelegate>

@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic) NSURLConnection *connection;
@property (nonatomic) NSMutableData *data;
@property (nonatomic, strong)
  UIViewController *(^handler)(NYPLRemoteViewController *remoteViewController, NSData *data, NSURLResponse *response);
@property (nonatomic) NYPLReloadView *reloadView;
@property (nonatomic, strong) NSURLResponse *response;

@end

@implementation NYPLRemoteViewController

- (instancetype)initWithURL:(NSURL *const)URL
          completionHandler:(UIViewController *(^ const)
                             (NYPLRemoteViewController *remoteViewController,
                              NSData *data,
                              NSURLResponse *response))handler
{
  self = [super init];
  if(!self) return nil;
  
  if(!handler) {
    @throw NSInvalidArgumentException;
  }
  
  self.handler = handler;
  self.URL = URL;
  
  return self;
}

- (void)load
{
  if(self.childViewControllers.count > 0) {
    UIViewController *const childViewController = self.childViewControllers[0];
    [childViewController.view removeFromSuperview];
    [childViewController removeFromParentViewController];
    [childViewController didMoveToParentViewController:nil];
  }
  
  [self.activityIndicatorView startAnimating];
  self.reloadView.hidden = YES;
  
  [[NYPLSession sharedSession] withURL:self.URL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    [self.activityIndicatorView stopAnimating];
  
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    
    // It should only ever be cancelled due to failing to authenticate
    if(error.code == NSURLErrorCancelled ||  httpResponse.statusCode == 401) {
    
        [NYPLSettingsAccountViewController
     requestCredentialsUsingExistingBarcode:NO
     completionHandler:^{
       [self load];
     }];

    
      self.reloadView.hidden = NO;
      return;
    }
      
    UIViewController *const viewController = self.handler(self, data, response);
  
    if(viewController) {
      [self addChildViewController:viewController];
      viewController.view.frame = self.view.bounds;
      [self.view addSubview:viewController.view];
      if(viewController.navigationItem.rightBarButtonItems) {
        self.navigationItem.rightBarButtonItems = viewController.navigationItem.rightBarButtonItems;
      }
      if(viewController.navigationItem.leftBarButtonItems) {
        self.navigationItem.leftBarButtonItems = viewController.navigationItem.leftBarButtonItems;
      }
      if(viewController.navigationItem.title) {
        self.navigationItem.title = viewController.navigationItem.title;
      }
      [viewController didMoveToParentViewController:self];
  } else {
      self.reloadView.hidden = NO;
  }
  }];
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
  
  self.activityIndicatorView = [[UIActivityIndicatorView alloc]
                                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  [self.view addSubview:self.activityIndicatorView];
  
  // We always nil out the connection when not in use so this is reliable.
  if(self.connection) {
    [self.activityIndicatorView startAnimating];
  }
  
  __weak NYPLRemoteViewController *weakSelf = self;
  self.reloadView = [[NYPLReloadView alloc] init];
  self.reloadView.handler = ^{
    weakSelf.reloadView.hidden = YES;
    [weakSelf load];
  };
  self.reloadView.hidden = YES;
  [self.view addSubview:self.reloadView];
}

- (void)viewWillLayoutSubviews
{
  [self.activityIndicatorView centerInSuperview];
  [self.activityIndicatorView integralizeFrame];
  
  [self.reloadView centerInSuperview];
  [self.reloadView integralizeFrame];
}

#pragma mark NSURLConnectionDataDelegate

- (void)connection:(__attribute__((unused)) NSURLConnection *)connection
    didReceiveData:(NSData *const)data
{
  [self.data appendData:data];
}

- (void)connection:(__attribute__((unused)) NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
  self.response = response;
}

- (void)connectionDidFinishLoading:(__attribute__((unused)) NSURLConnection *)connection
{
  [self.activityIndicatorView stopAnimating];
  
  if ([(NSHTTPURLResponse *)self.response statusCode] != 200
      && ([self.response.MIMEType isEqualToString:@"application/problem+json"]
          || [self.response.MIMEType isEqualToString:@"application/api-problem+json"])) {
    NYPLProblemDocument *problem = [NYPLProblemDocument problemDocumentWithData:self.data];
    NYPLAlertController *alert = [NYPLAlertController alertWithTitle:problem.title message:problem.detail];
    [alert setProblemDocument:problem displayDocumentMessage:NO];
    [self presentViewController:alert animated:YES completion:nil];
  }
  
  UIViewController *const viewController = self.handler(self, self.data, self.response);
  
  if(viewController) {
    [self addChildViewController:viewController];
    viewController.view.frame = self.view.bounds;
    [self.view addSubview:viewController.view];
    if(viewController.navigationItem.rightBarButtonItems) {
      self.navigationItem.rightBarButtonItems = viewController.navigationItem.rightBarButtonItems;
    }
    if(viewController.navigationItem.leftBarButtonItems) {
      self.navigationItem.leftBarButtonItems = viewController.navigationItem.leftBarButtonItems;
    }
    if(viewController.navigationItem.title) {
      self.navigationItem.title = viewController.navigationItem.title;
    }
    [viewController didMoveToParentViewController:self];
  } else {
    self.reloadView.hidden = NO;
  }
  
  self.response = nil;
  self.connection = nil;
  self.data = nil;
}

#pragma mark NSURLConnectionDelegate

- (void)connection:(__attribute__((unused)) NSURLConnection *)connection
  didFailWithError:(__attribute__((unused)) NSError *)error
{
  [self.activityIndicatorView stopAnimating];
  
  self.reloadView.hidden = NO;
  
  self.connection = nil;
  self.data = nil;
  self.response = nil;
}

@end
