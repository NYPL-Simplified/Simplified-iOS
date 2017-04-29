#import "NYPLConfiguration.h"
#import "NYPLReloadView.h"
#import "NYPLRemoteViewController.h"
#import "NYPLSettings.h"
#import "UIView+NYPLViewAdditions.h"
#import "NYPLAlertController.h"
#import "NYPLProblemDocument.h"
#import <PureLayout/PureLayout.h>

@interface NYPLRemoteViewController () <NSURLConnectionDataDelegate>

@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic) UILabel *activityIndicatorLabel;
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
  self.reloadView.hidden = YES;
  
  while(self.childViewControllers.count > 0) {
    UIViewController *const childViewController = self.childViewControllers[0];
    [childViewController.view removeFromSuperview];
    [childViewController removeFromParentViewController];
    [childViewController didMoveToParentViewController:nil];
  }
  
  [self.connection cancel];
  
  NSTimeInterval timeoutInterval = 30.0;
  NSTimeInterval activityLabelTimer = 10.0;
  
  NSURLRequest *const request = [NSURLRequest requestWithURL:self.URL
                                                 cachePolicy:NSURLRequestUseProtocolCachePolicy
                                             timeoutInterval:timeoutInterval];
  
  self.activityIndicatorLabel.hidden = YES;
  [NSTimer scheduledTimerWithTimeInterval: activityLabelTimer target: self
                                 selector: @selector(addActivityIndicatorLabel:) userInfo: nil repeats: NO];
  
  self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
  self.data = [NSMutableData data];
  
  [self.activityIndicatorView startAnimating];
  
  [self.connection start];
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
  
  self.activityIndicatorView = [[UIActivityIndicatorView alloc]
                                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  [self.view addSubview:self.activityIndicatorView];
  
  self.activityIndicatorLabel = [[UILabel alloc] init];
  self.activityIndicatorLabel.font = [UIFont systemFontOfSize:14.0];
  self.activityIndicatorLabel.text = NSLocalizedString(@"ActivitySlowLoadMessage", @"Message explaining that the download is still going");
  self.activityIndicatorLabel.hidden = YES;
  [self.view addSubview:self.activityIndicatorLabel];
  [self.activityIndicatorLabel autoAlignAxis:ALAxisVertical toSameAxisOfView:self.activityIndicatorView];
  [self.activityIndicatorLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.activityIndicatorView withOffset:8.0];
  
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

- (void)addActivityIndicatorLabel:(NSTimer*)timer
{
  if (!self.activityIndicatorView.isHidden) {
    [UIView transitionWithView:self.activityIndicatorLabel
                      duration:0.5
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                      self.activityIndicatorLabel.hidden = NO;
                    } completion:nil];
  }
  [timer invalidate];
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
  self.activityIndicatorLabel.hidden = YES;
  
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
  self.data = [NSMutableData data];
}

#pragma mark NSURLConnectionDelegate

- (void)connection:(__attribute__((unused)) NSURLConnection *)connection
  didFailWithError:(__attribute__((unused)) NSError *)error
{
  [self.activityIndicatorView stopAnimating];
  self.activityIndicatorLabel.hidden = YES;
  
  self.reloadView.hidden = NO;
  
//  if (error) {
//    NYPLAlertController *alert = [NYPLAlertController alertWithTitle:@"Error" error:error];
//    [self presentViewController:alert animated:YES completion:nil];
//  }
  
  self.connection = nil;
  self.data = [NSMutableData data];
  self.response = nil;
}

@end
