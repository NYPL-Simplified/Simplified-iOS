#import "NYPLConfiguration.h"
#import "NYPLReloadView.h"
#import "NYPLRemoteViewController.h"

#import "UIView+NYPLViewAdditions.h"
#import "SimplyE-Swift.h"

#import <PureLayout/PureLayout.h>

@interface NYPLRemoteViewController () <NSURLConnectionDataDelegate>

@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic) UILabel *activityIndicatorLabel;
@property (nonatomic) NYPLReloadView *reloadView;
@property (nonatomic) NSURLConnection *connection;
@property (nonatomic) NSMutableData *data;
@property (nonatomic, copy) UIViewController *(^handler)(NYPLRemoteViewController *remoteViewController, NSData *data, NSURLResponse *response);
@property (nonatomic, strong) NSURLResponse *response;
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
  self.activityIndicatorLabel.hidden = YES;
  [self.activityIndicatorView stopAnimating];
}

- (void)loadWithURL:(NSURL*)url
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
  
  [self.connection cancel];

  [self.activityIndicatorView startAnimating];

  // TODO: SIMPLY-2862
  // From the point of view of this VC, there is no point in attempting to
  // load a remote page if we have no URL. Upon inspection of the codebase,
  // this happens only in 2 situations:
  // 1. at navigation controllers / app initialization time, when they are
  //    initialized with dummy VCs that have nil URLs. These VCs will be
  //    replaced once we obtain the catalog from the authentication document of
  //    the current library. Expressing this in code is the point of SIMPLY-2862.
  // 2. If the request for loading the library accounts and the current
  //    library's authentication document fail.
  // These 2 situations are hard to distinguish from here. However, both
  // can be handled by attempting a reload of the library accounts
  // and auth doc. This is ok even for case #1 bc there's instrumentation in
  // AccountManager for ignoring a call if there's one already ongoing.
  // If those request succeed, there's instrumentation in AccountManager and
  // NYPLRootTabBarController to trigger the creation of a new
  // NYPLRemoteViewController furnished this time with a non-nil catalog URL.
  //
  // There's a 3rd case to consider also, and that is if the VC was purposedly
  // set up with a nil URL. While that looks like a programmer error, it will
  // result in a needless reload of the accounts/auth doc, but it will end up
  // showing the reload UI anyway.
  //
  // Obviously this level of coupling is dreadful, and SIMPLY-2862 should
  // address this as well.
  if (self.URL == nil) {
    [self reloadAccountsAndAuthenticationDocument];
    return;
  }

  NSTimeInterval timeoutInterval = 30.0;
  NSTimeInterval activityLabelTimer = 10.0;

  NSURLRequest *const request = [NSURLRequest requestWithURL:self.URL
                                                 cachePolicy:NSURLRequestUseProtocolCachePolicy
                                             timeoutInterval:timeoutInterval];

  // show "slow loading" label after `activityLabelTimer` seconds
  self.activityIndicatorLabel.hidden = YES;
  [NSTimer scheduledTimerWithTimeInterval: activityLabelTimer target: self
                                 selector: @selector(addActivityIndicatorLabel:) userInfo: nil repeats: NO];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  // TODO: SIMPLY-2589 Replace with NSURLSession
  self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
#pragma clang diagnostic pop
  self.data = [NSMutableData data];
  
  [self.connection start];
}

// TODO: SIMPLY-2862 This method should be removed as part of this ticket
- (void)reloadAccountsAndAuthenticationDocument
{
  NYPLLOG_F(@"Reloading accounts from RemoteVC: %@", self.title);
  [AccountsManager.shared updateAccountSetWithCompletion:^(BOOL success) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (success) {
        // since we have the accounts, now we can do a proper reload
        [self load];
      } else {
        [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeNoURL
                                  context:@"RemoteViewController"
                                  message:@"Failed to reload accounts after having found nil URL"
                                 metadata:@{
                                   @"currentURL": self.URL ?: @"N/A",
                                   @"Response": self.response ?: @"N/A",
                                   @"ChildVCs": self.childViewControllers
                                 }];
        [self showReloadViewWithMessage:nil];
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
  [super viewWillLayoutSubviews];

  [self.activityIndicatorView centerInSuperview];
  [self.reloadView centerInSuperview];
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

  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)self.response;
  if ([httpResponse statusCode] != 200) {
    [self handleErrorResponse:httpResponse];
  }
  
  UIViewController *const vc = self.handler(self, self.data, self.response);
  
  if (vc) {
    [self addChildViewController:vc];
    vc.view.frame = self.view.bounds;
    [self.view addSubview:vc.view];

    // If `vc` has its own bar button items or title, use whatever
    // has been set by default.
    if(vc.navigationItem.rightBarButtonItems) {
      self.navigationItem.rightBarButtonItems = vc.navigationItem.rightBarButtonItems;
    }
    if(vc.navigationItem.leftBarButtonItems) {
      self.navigationItem.leftBarButtonItems = vc.navigationItem.leftBarButtonItems;
    }
    if(vc.navigationItem.backBarButtonItem) {
      self.navigationItem.backBarButtonItem = vc.navigationItem.backBarButtonItem;
    }
    if(vc.navigationItem.title) {
      self.navigationItem.title = vc.navigationItem.title;
    }

    [vc didMoveToParentViewController:self];
  } else {
    [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeUnableToMakeVCAfterLoading
                              context:@"RemoteViewController"
                              message:@"Failed to create VC after loading from server"
                             metadata:@{
                               @"HTTPstatusCode": @(httpResponse.statusCode),
                               @"response.mimeType": httpResponse.MIMEType ?: @"N/A",
                               @"URL": self.URL ?: @"N/A",
                               @"response": httpResponse ?: @"N/A"
                             }];
    self.reloadView.hidden = NO;
  }

  [self resetConnectionInfo];
}

#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
  [self.activityIndicatorView stopAnimating];
  self.activityIndicatorLabel.hidden = YES;
  
  self.reloadView.hidden = NO;
  
  NSDictionary<NSString*, NSObject*> *metadata = @{
    @"remoteVC.URL": self.URL ?: @"none",
    @"connection.currentRequest": connection.currentRequest.loggableString ?: @"none",
    @"connection.originalRequest": connection.originalRequest.loggableString ?: @"none",
  };
  [NYPLErrorLogger logError:error
                    context:@"RemoteViewController"
                    message:@"Server-side api call (likely related to Catalog loading) did fail with network error"
                   metadata:metadata];

  [self resetConnectionInfo];
}

#pragma mark Private Helpers

- (void)resetConnectionInfo
{
  self.response = nil;
  self.connection = nil;
  self.data = [NSMutableData data];
}

- (void)handleErrorResponse:(NSHTTPURLResponse *)httpResponse
{
  if (httpResponse.isProblemDocument) {
    NSError *problemDocumentParseError = nil;
    NYPLProblemDocument *pDoc = [NYPLProblemDocument fromData:self.data error:&problemDocumentParseError];
    UIAlertController *alert;

    if (problemDocumentParseError) {
      [NYPLErrorLogger logProblemDocumentParseError:problemDocumentParseError
                                problemDocumentData:self.data
                                            barcode:nil
                                                url:[self.response URL]
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
