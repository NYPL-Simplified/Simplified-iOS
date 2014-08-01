#import "NYPLAccount.h"
#import "NYPLConfiguration.h"
#import "NYPLRootTabBarController.h"
#import "NYPLSettingsCredentialView.h"

#import "NYPLSettingsCredentialViewController.h"

@interface NYPLSettingsCredentialViewController ()
  <NSURLSessionDelegate, NSURLSessionTaskDelegate, UITextFieldDelegate>

@property (nonatomic) BOOL shouldAnswerChallenge;
@property (nonatomic, readonly) NYPLSettingsCredentialView *credentialView;
@property (nonatomic, copy) void (^completionHandler)();
@property (nonatomic) NSURLSession *session;
@property (nonatomic) UIView *shieldView;
@property (nonatomic) UIViewController *viewController;

@end

@implementation NYPLSettingsCredentialViewController

+ (instancetype)sharedController
{
  static dispatch_once_t predicate;
  static NYPLSettingsCredentialViewController *sharedController = nil;
  
  dispatch_once(&predicate, ^{
    sharedController = [[self alloc] initWithNibName:@"NYPLSettingsCredentialView"
                                              bundle:[NSBundle mainBundle]];
    if(!sharedController) {
      NYPLLOG(@"Failed to create shared settings credential controller.");
    }
  });
  
  return sharedController;
}

- (NYPLSettingsCredentialView *)credentialView
{
  return (NYPLSettingsCredentialView *)self.view;
}

#pragma mark UIViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil
                         bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if(!self) return nil;
  
  self.modalPresentationStyle = UIModalPresentationFormSheet;
  
  self.credentialView.navigationItem.leftBarButtonItem.action = @selector(didSelectCancel);
  self.credentialView.navigationItem.leftBarButtonItem.target = self;
  
  self.credentialView.navigationItem.rightBarButtonItem.action = @selector(didSelectContinue);
  self.credentialView.navigationItem.rightBarButtonItem.target = self;
  
  [self.credentialView.barcodeField
   addTarget:self
   action:@selector(fieldsDidChange)
   forControlEvents:UIControlEventEditingChanged];
  
  self.credentialView.barcodeField.delegate = self;
  
  [self.credentialView.PINField
   addTarget:self
   action:@selector(fieldsDidChange)
   forControlEvents:UIControlEventEditingChanged];
  
  self.credentialView.PINField.delegate = self;
  
  NSURLSessionConfiguration *const configuration =
    [NSURLSessionConfiguration ephemeralSessionConfiguration];
  
  configuration.timeoutIntervalForResource = 5.0;
  
  self.session = [NSURLSession
                  sessionWithConfiguration:configuration
                  delegate:self
                  delegateQueue:[NSOperationQueue mainQueue]];
  
  return self;
}

- (void)viewWillAppear:(__attribute__((unused)) BOOL)animated
{
  [self.credentialView.barcodeField becomeFirstResponder];
}

#pragma mark UITextViewDelegate

- (BOOL)textFieldShouldReturn:(UITextField *const)textField
{
  if(textField == self.credentialView.barcodeField) {
    [self.credentialView.PINField becomeFirstResponder];
  } else {
    [self.credentialView.PINField resignFirstResponder];
  }
  
  return YES;
}

#pragma mark NSURLSessionDelegate

- (void)URLSession:(__attribute__((unused)) NSURLSession *)session
              task:(__attribute__((unused)) NSURLSessionTask *)task
didReceiveChallenge:(__attribute__((unused)) NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                             NSURLCredential *credential))completionHandler
{
  if(self.shouldAnswerChallenge) {
    self.shouldAnswerChallenge = NO;
    completionHandler(NSURLSessionAuthChallengeUseCredential,
                      [NSURLCredential
                       credentialWithUser:self.credentialView.barcodeField.text
                       password:self.credentialView.PINField.text
                       persistence:NSURLCredentialPersistenceNone]);
  } else {
    completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
  }
}

#pragma mark -

- (void)
requestCredentialsUsingExistingBarcode:(BOOL const)useExistingBarcode
message:(NYPLSettingsCredentialViewControllerMessage const)message
completionHandler:(void (^)())handler
{
  if(self.completionHandler) {
    @throw NSInternalInconsistencyException;
  }
  
  self.completionHandler = handler;
  
  if(useExistingBarcode) {
    NSString *const barcode = [NYPLAccount sharedAccount].barcode;
    if(!barcode) {
      @throw NSInvalidArgumentException;
    }
    self.credentialView.barcodeField.text = barcode;
  } else {
    self.credentialView.barcodeField.text = @"";
  }
  
  self.credentialView.PINField.text = @"";
  self.credentialView.navigationItem.rightBarButtonItem.enabled = NO;
  
  switch(message) {
    case NYPLSettingsCredentialViewControllerMessageLogIn:
      self.credentialView.messageLabel.text =
        NSLocalizedString(@"NYPLSettingsCredentialViewControllerMessageLogIn", nil);
      break;
    case NYPLSettingsCredentialViewControllerMessageLogInToDownloadBook:
      self.credentialView.messageLabel.text =
        NSLocalizedString(@"NYPLSettingsCredentialViewControllerMessageLogInToDownloadBook", nil);
      break;
    case NYPLSettingsCredentialViewControllerMessageInvalidPin:
      self.credentialView.messageLabel.text =
        NSLocalizedString(@"NYPLSettingsCredentialViewControllerMessageInvalidPIN", nil);
      break;
  }
  
  [[NYPLRootTabBarController sharedController]
   safelyPresentViewController:self
   animated:YES
   completion:nil];
}

- (void)didSelectCancel
{
  [self dismissViewControllerAnimated:YES completion:nil];
  
  self.completionHandler = nil;
}

- (void)fieldsDidChange
{
  self.credentialView.navigationItem.rightBarButtonItem.enabled =
  (self.credentialView.barcodeField.text.length > 0 &&
   self.credentialView.PINField.text.length > 0);
}

- (void)setShieldEnabled:(BOOL)enabled
{
  if(enabled && !self.shieldView) {
    [self.credentialView.barcodeField resignFirstResponder];
    [self.credentialView.PINField resignFirstResponder];
    self.shieldView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.shieldView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                        UIViewAutoresizingFlexibleHeight);
    self.shieldView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    UIActivityIndicatorView *const activityIndicatorView =
      [[UIActivityIndicatorView alloc]
        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicatorView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
                                              UIViewAutoresizingFlexibleRightMargin |
                                              UIViewAutoresizingFlexibleTopMargin |
                                              UIViewAutoresizingFlexibleBottomMargin);
    [self.shieldView addSubview:activityIndicatorView];
    activityIndicatorView.center = self.shieldView.center;
    [activityIndicatorView startAnimating];
    [self.view addSubview:self.shieldView];
  } else {
    [self.shieldView removeFromSuperview];
    self.shieldView = nil;
  }
}

- (void)didSelectContinue
{
  assert(self.credentialView.barcodeField.text.length > 0);
  assert(self.credentialView.PINField.text.length > 0);
  
  [self setShieldEnabled:YES];
  
  [self validateCredentials];
}

- (void)validateCredentials
{
  NSMutableURLRequest *const request =
    [NSMutableURLRequest requestWithURL:[NYPLConfiguration loanURL]];
  
  request.HTTPMethod = @"HEAD";
  
  self.shouldAnswerChallenge = YES;
  
  NSURLSessionDataTask *const task =
    [self.session
     dataTaskWithRequest:request
     completionHandler:^(__attribute__((unused)) NSData *data,
                         NSURLResponse *const response,
                         NSError *const error) {
       
       [self setShieldEnabled:NO];
       
       if(error.code == NSURLErrorNotConnectedToInternet) {
         [[[UIAlertView alloc]
           initWithTitle:NSLocalizedString(@"NYPLSettingsCredentialViewControllerLoginFailed", nil)
           message:NSLocalizedString(@"NotConnected", nil)
           delegate:nil
           cancelButtonTitle:nil
           otherButtonTitles:NSLocalizedString(@"OK", nil), nil]
          show];
         return;
       }
       
       if(error.code == NSURLErrorCancelled) {
         // We cancelled the request when asked to answer the server's challenge a second time
         // because we don't have valid credentials.
         [[[UIAlertView alloc]
           initWithTitle:NSLocalizedString(@"NYPLSettingsCredentialViewControllerLoginFailed", nil)
           message:NSLocalizedString(@"NYPLSettingsCredentialViewControllerInvalidCredentials", nil)
           delegate:nil
           cancelButtonTitle:nil
           otherButtonTitles:NSLocalizedString(@"OK", nil), nil]
          show];
         self.credentialView.PINField.text = @"";
         [self fieldsDidChange];
         [self.credentialView.PINField becomeFirstResponder];
         return;
       }
       
       if(error.code == NSURLErrorTimedOut) {
         [[[UIAlertView alloc]
           initWithTitle:NSLocalizedString(@"NYPLSettingsCredentialViewControllerLoginFailed", nil)
           message:NSLocalizedString(@"TimedOut", nil)
           delegate:nil
           cancelButtonTitle:nil
           otherButtonTitles:NSLocalizedString(@"OK", nil), nil]
          show];
         return;
       }
       
       // This cast is always valid according to Apple's documentation for NSHTTPURLResponse.
       NSInteger statusCode = ((NSHTTPURLResponse *) response).statusCode;
       
       if(statusCode == 200) {
         [[NYPLAccount sharedAccount] setBarcode:self.credentialView.barcodeField.text
                                             PIN:self.credentialView.PINField.text];
         [self dismissViewControllerAnimated:YES completion:^{}];
         void (^handler)() = self.completionHandler;
         self.completionHandler = nil;
         handler();
         return;
       }
       
       NYPLLOG(@"Encountered unexpected error after authenticating.");
       
       [[[UIAlertView alloc]
         initWithTitle:NSLocalizedString(@"NYPLSettingsCredentialViewControllerLoginFailed", nil)
         message:NSLocalizedString(@"UnknownRequestError", nil)
         delegate:nil
         cancelButtonTitle:nil
         otherButtonTitles:NSLocalizedString(@"OK", nil), nil]
        show];
     }];
  
  [task resume];
}

@end
