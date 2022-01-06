@import PureLayout;

#import "NYPLConfiguration.h"
#import "NYPLReloadView.h"
#import "NYPLRemoteViewController.h"

#import "NSString+NYPLStringAdditions.h"
#import "UIView+NYPLViewAdditions.h"
#import "SimplyE-Swift.h"

@interface NYPLRemoteViewController () <NSURLConnectionDataDelegate>

@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic) UILabel *activityIndicatorLabel;
@property (nonatomic) NYPLReloadView *reloadView;
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, copy) UIViewController *(^handler)(NYPLRemoteViewController *remoteViewController, NSData *data, NSURLResponse *response);
@property (atomic, readwrite) NSURL *URL;
@property BOOL needsReauthentication;

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
  if (message != nil && ![message isEmptyNoWhitespace]) {
    [self.reloadView setMessage:message];
  } else {
    [self.reloadView setDefaultMessage];
  }

  self.reloadView.hidden = NO;
  self.activityIndicatorLabel.hidden = YES;
  [self.activityIndicatorView stopAnimating];
}

- (void)loadWithURL:(NSURL* _Nonnull)url
{
  NYPLLOG_F(@"url=%@", url);
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
    [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeNoURL
                              summary:@"RemoteViewController: Prevented load with no URL"
                             metadata:@{
                               @"ChildVCs": self.childViewControllers
                             }];
    [self reloadAccountsAndAuthenticationDocument];
    return;
  }

  // show "slow loading" label after `activityLabelTimer` seconds
  self.activityIndicatorLabel.hidden = YES;
  [NSTimer scheduledTimerWithTimeInterval: activityLabelTimer target: self
                                 selector: @selector(addActivityIndicatorLabel:) userInfo: nil repeats: NO];

  NYPLLOG_F(@"RemoteVC: issueing request [%@]", [request loggableString]);
  self.dataTask = [NYPLNetworkExecutor.shared addBearerAndExecute:request
                           completion:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {

    NSHTTPURLResponse *httpResponse = nil;
    if ([response isKindOfClass: [NSHTTPURLResponse class]]) {
      httpResponse = (NSHTTPURLResponse *) response;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.activityIndicatorView stopAnimating];
      self.activityIndicatorLabel.hidden = YES;
      NSURLSessionDataTask *dataTaskCopy = self.dataTask;
      self.dataTask = nil;

      NYPLProblemDocument *problemDoc = [NYPLProblemDocument
                                         fromResponseError:error
                                         responseData: data];
      self.needsReauthentication = [response indicatesAuthenticationNeedsRefresh:problemDoc];

      if (error || self.needsReauthentication || ![httpResponse isSuccess]) {
        [self showReloadViewWithMessage:[self messageFromProblemDocument:problemDoc
                                                                   error:error]];
        NSDictionary<NSString*, NSObject*> *metadata = @{
          @"remoteVC.URL": self.URL ?: @"none",
          @"connection.currentRequest": dataTaskCopy.currentRequest ?: @"none",
          @"connection.originalRequest": dataTaskCopy.originalRequest ?: @"none",
        };
        [NYPLErrorLogger logError:error
                          summary:@"RemoteViewController server-side load error"
                         metadata:metadata];

        return;
      }

      self.needsReauthentication = NO;

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
                                  summary:@"RemoteViewController: Failed to create VC after server-side load"
                                 metadata:@{
                                   @"HTTPstatusCode": @(httpResponse.statusCode ?: -1),
                                   @"mimeType": response.MIMEType ?: @"N/A",
                                   @"URL": self.URL ?: @"N/A",
                                   @"response": response ?: @"N/A"
                                 }];
        [self showReloadViewWithMessage:
         NSLocalizedString(@"An error was encountered while parsing the server response.",
                           @"Generic error message for catalog load errors")];
      }
    });
  }];
}

// TODO: SIMPLY-2862 This method should be removed as part of this ticket
- (void)reloadAccountsAndAuthenticationDocument
{
  NYPLLOG_F(@"Reloading accounts from RemoteVC: %@", self.title);
  [AccountsManager.shared updateAccountSetWithCompletion:^(BOOL success) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (success) {
        if (self.needsReauthentication) {
          self.needsReauthentication = NO;

          NYPLUserAccount *user = [NYPLUserAccount sharedAccount];
          __block NYPLReauthenticator *reauthenticator = [[NYPLReauthenticator alloc] init];
          [reauthenticator authenticateIfNeeded:user
                       usingExistingCredentials:YES
                       authenticationCompletion:^{
            // make sure to retain the reauthenticator until end of auth
            // flow and then break any possible retain cycle
            reauthenticator = nil;
            NYPLLOG(@"Re-loading from RemoteVC because authentication had expired");
            [self load];
          }];
        } else {
          [self load];
        }
      } else {
        [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeNoURL
                                  summary:@"RemoteViewController: failed to reload accounts"
                                 metadata:@{
                                   @"currentURL": self.URL ?: @"N/A",
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
  
  self.view.backgroundColor = [NYPLConfiguration primaryBackgroundColor];
  
  self.activityIndicatorView = [[UIActivityIndicatorView alloc]
                                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  [self.view addSubview:self.activityIndicatorView];
  
  self.activityIndicatorLabel = [[UILabel alloc] init];
  self.activityIndicatorLabel.font = [UIFont systemFontOfSize:14.0];
  self.activityIndicatorLabel.text = NSLocalizedString(@"Loading... Please wait.", @"Message explaining that the download is still going");
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

#pragma mark Private Helpers

- (NSString *)messageFromProblemDocument:(NYPLProblemDocument *)problemDoc
                                   error:(NSError *)error
{
  if (problemDoc && !problemDoc.stringValue.isEmptyNoWhitespace) {
    return problemDoc.stringValue;
  }

  if (error && !error.localizedDescriptionWithRecovery.isEmptyNoWhitespace) {
    return error.localizedDescriptionWithRecovery;
  }

  return NSLocalizedString(@"Load error. Please try signing out, then log in again.",
                           @"message for edge-case errors possibly related to authentication");
}

@end
