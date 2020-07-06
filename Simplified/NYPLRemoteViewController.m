#import "NYPLConfiguration.h"
#import "NYPLReloadView.h"
#import "NYPLRemoteViewController.h"

#import "UIView+NYPLViewAdditions.h"
#import "SimplyE-Swift.h"

#import <PureLayout/PureLayout.h>

@interface NYPLRemoteViewController () <NSURLConnectionDataDelegate>

@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic) UILabel *activityIndicatorLabel;
@property (nonatomic, copy) UIViewController *(^handler)(NYPLRemoteViewController *remoteViewController, NSData *data, NSURLResponse *response);
@property (nonatomic) NYPLReloadView *reloadView;
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

@end

@implementation NYPLRemoteViewController

- (instancetype)initWithURL:(NSURL *const)URL
                    handler:(UIViewController *(^ const)
                             (NYPLRemoteViewController *remoteViewController,
                              NSData *data,
                              NSURLResponse *response))handler
{
  self = [super initWithNibName:nil bundle:nil];
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
  
  [self.dataTask cancel];
  
  NSTimeInterval timeoutInterval = 30.0;
  NSTimeInterval activityLabelTimer = 10.0;

    NSMutableURLRequest *const request = [[NSURLRequest requestWithURL:self.URL
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:timeoutInterval] mutableCopy];


  self.activityIndicatorLabel.hidden = YES;
  [NSTimer scheduledTimerWithTimeInterval: activityLabelTimer target: self
                                 selector: @selector(addActivityIndicatorLabel:) userInfo: nil repeats: NO];

  request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
  self.dataTask = [NYPLNetworkExecutor.shared execute:request
                           completion:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {

    dispatch_async(dispatch_get_main_queue(), ^{
      [self.activityIndicatorView stopAnimating];
      self.activityIndicatorLabel.hidden = YES;
      self.dataTask = nil;

      if ([response.MIMEType isEqualToString:@"application/vnd.opds.authentication.v1.0+json"]) {
        self.reloadView.hidden = false;
        [NYPLAccountSignInViewController requestCredentialsUsingExistingBarcode:([NYPLUserAccount sharedAccount].barcode) completionHandler:^{
          [self load];
        }];
        return;
      }

      if (error) {
        self.reloadView.hidden = NO;
        [NYPLErrorLogger logCatalogLoadError:error url:self.URL];
        return;
      }

      BOOL mimeTypeMatches = [response.MIMEType isEqualToString:@"application/problem+json"] ||
      [response.MIMEType isEqualToString:@"application/api-problem+json"];

      if ([(NSHTTPURLResponse *)response statusCode] != 200 && mimeTypeMatches) {
        NSError *problemDocumentParseError = nil;
        NYPLProblemDocument *pDoc = [NYPLProblemDocument fromData:data error:&problemDocumentParseError];
        UIAlertController *alert;
        if (problemDocumentParseError) {
          [NYPLErrorLogger logProblemDocumentParseError:problemDocumentParseError
                                                    url:[response URL]
                                                context:@"RemoteVC-errorResponse"];
          alert = [NYPLAlertUtils
                   alertWithTitle:NSLocalizedString(@"Error", @"Title for a generic error")
                   message:NSLocalizedString(@"Unknown error parsing problem document",
                                             @"Message for a problem document error")];
        } else {
          alert = [NYPLAlertUtils alertWithTitle:pDoc.title message:pDoc.detail];
        }
        [self presentViewController:alert animated:YES completion:nil];
      }

      UIViewController *const viewController = self.handler(self, data, response);

      if (viewController) {
        [self addChildViewController:viewController];
        viewController.view.frame = self.view.bounds;
        [self.view addSubview:viewController.view];

        // If `viewController` has its own bar button items or title, use whatever
        // has been set by default.
        if(viewController.navigationItem.rightBarButtonItems) {
          self.navigationItem.rightBarButtonItems = viewController.navigationItem.rightBarButtonItems;
        }
        if(viewController.navigationItem.leftBarButtonItems) {
          self.navigationItem.leftBarButtonItems = viewController.navigationItem.leftBarButtonItems;
        }
        if(viewController.navigationItem.backBarButtonItem) {
          self.navigationItem.backBarButtonItem = viewController.navigationItem.backBarButtonItem;
        }
        if(viewController.navigationItem.title) {
          self.navigationItem.title = viewController.navigationItem.title;
        }

        [viewController didMoveToParentViewController:self];
      } else {
        self.reloadView.hidden = NO;
      }
    });
  }];

//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wdeprecated-declarations"
//  // TODO: SIMPLY-2589 Replace with NSURLSession
//  self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
//#pragma clang diagnostic pop
//  self.data = [NSMutableData data];
//
//  [self.activityIndicatorView startAnimating];
//
//  [self.connection start];
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
  if(self.dataTask) {
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

@end
