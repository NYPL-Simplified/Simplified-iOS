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
@property (atomic, readwrite) NSURL *URL;

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

- (void)showReloadViewWithMessage:(NSString*)message
{
  if (message != nil) {
    [self.reloadView setMessage:message];
  } else {
    [self.reloadView setDefaultMessage];
  }

  self.reloadView.hidden = NO;
}

- (void)loadWithURL:(NSURL* _Nonnull)url
{
  self.URL = url;
  [self load];
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

  // NSURLRequestUseProtocolCachePolicy originally, but pull to refresh on a catalog
  NSURLRequest *const request = [NSURLRequest requestWithURL:self.URL
                                                 cachePolicy:NSURLRequestUseProtocolCachePolicy
                                             timeoutInterval:timeoutInterval];


  [self.activityIndicatorView startAnimating];

  // TODO: SIMPLY-2862
  // From the point of view of this VC, there is no point in attempting to
  // load a remote page if we have no URL.
  // Upon inspection of the codebase, this happens only at navigation
  // controllers initialization time, when basically they are initialized
  // with dummy VCs that have nil URLs which will be replaced once we obtain
  // the catalog from the authentication document. Expressing this in code
  // is the point of SIMPLY-2862.
  if (self.URL == nil) {
    [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeNoURL
                              context:@"RemoteViewController"
                              message:@"Prevented attempt to load without a URL."
                             metadata:@{
                               @"ChildVCs": self.childViewControllers
                             }];
    return;
  }

  // show "slow loading" label after `activityLabelTimer` seconds
  self.activityIndicatorLabel.hidden = YES;
  [NSTimer scheduledTimerWithTimeInterval: activityLabelTimer target: self
                                 selector: @selector(addActivityIndicatorLabel:) userInfo: nil repeats: NO];

  self.dataTask = [NYPLNetworkExecutor.shared addBearerAndExecute:request
                           completion:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {

    dispatch_async(dispatch_get_main_queue(), ^{
      [self.activityIndicatorView stopAnimating];
      self.activityIndicatorLabel.hidden = YES;
      NSURLSessionDataTask *dataTaskCopy = self.dataTask;
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
        NSDictionary<NSString*, NSObject*> *metadata = @{
          @"remoteVC.URL": self.URL ?: @"none",
          @"connection.currentRequest": dataTaskCopy.currentRequest ?: @"none",
          @"connection.originalRequest": dataTaskCopy.originalRequest ?: @"none",
        };
        [NYPLErrorLogger logError:error
                          context:@"RemoteViewController"
                          message:@"Server-side api call (likely related to Catalog loading) failed"
                         metadata:metadata];

        return;
      }

      NSHTTPURLResponse *httpResponse;
      if ([response isKindOfClass: [NSHTTPURLResponse class]]) {
        httpResponse = (NSHTTPURLResponse *) response;
        if (httpResponse.statusCode != 200) {
          [self handleErrorResponse:httpResponse withData:data];
        }
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
        [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeUnableToMakeVCAfterLoading
                                  context:@"RemoteViewController"
                                  message:@"Failed to create VC after loading from server"
                                 metadata:@{
                                   @"HTTPstatusCode": @(httpResponse.statusCode ?: -1),
                                   @"mimeType": response.MIMEType ?: @"N/A",
                                   @"URL": self.URL ?: @"N/A",
                                   @"response.URL": response.URL ?: @"N/A"
                                 }];
        self.reloadView.hidden = NO;
      }
    });
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
  [super viewWillLayoutSubviews];

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

#pragma mark Private Helpers

- (void)handleErrorResponse:(NSHTTPURLResponse *)httpResponse withData:(NSData * _Nullable) data
{
  BOOL mimeTypeMatches = [httpResponse.MIMEType isEqualToString:@"application/problem+json"] ||
  [httpResponse.MIMEType isEqualToString:@"application/api-problem+json"];

  if (mimeTypeMatches) {
    NSError *problemDocumentParseError = nil;
    NYPLProblemDocument *pDoc = [NYPLProblemDocument fromData:data error:&problemDocumentParseError];
    UIAlertController *alert;

    if (problemDocumentParseError) {
      [NYPLErrorLogger logProblemDocumentParseError:problemDocumentParseError
                                            barcode:nil
                                                url:httpResponse.URL
                                            context:@"RemoteViewController"
                                            message:@"Server-side api call (likely related to Catalog loading) failed and couldn't parse the problem doc either"];
      alert = [NYPLAlertUtils
               alertWithTitle:NSLocalizedString(@"Error", @"Title for a generic error")
               message:NSLocalizedString(@"Unknown error parsing problem document",
                                         @"Message for a problem document error")];
    } else {
      [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeProblemDocMessageDisplayed
                                context:@"RemoteViewController"
                                message:@"Server-side api call (likely related to Catalog loading) failed"
                               metadata:pDoc.debugDictionary];
      alert = [NYPLAlertUtils alertWithTitle:pDoc.title message:pDoc.detail];
    }
    [self presentViewController:alert animated:YES completion:nil];
  } else {
    // not a 200 but also no problem doc: this could be an error or not
    // depending on the mimeType and the data
    [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeUnexpectedHTTPCodeWarning
                              context:@"RemoteViewController"
                              message:@"Server-side api call (likely related to Catalog loading) returned a non-200 HTTP status"
                             metadata:@{
                               @"HTTPstatusCode": @(httpResponse.statusCode),
                               @"mimeType": httpResponse.MIMEType,
                               @"URL": self.URL ?: @"N/A",
                               @"response.URL": httpResponse.URL ?: @"N/A"
                             }];
  }
}

@end
