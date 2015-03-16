#import "NYPLAccount.h"
#import "NYPLBookCoverRegistry.h"
#import "NYPLBookRegistry.h"
#import "NYPLConfiguration.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLSettingsCredentialViewController.h"
#import "UIView+NYPLViewAdditions.h"

#import "NYPLSettingsAccountViewController.h"

typedef NS_ENUM(NSInteger, CellKind) {
  CellKindBarcode,
  CellKindPIN,
  CellKindLoginLogout
};

static CellKind CellKindFromIndexPath(NSIndexPath *const indexPath)
{
  switch(indexPath.section) {
    case 0:
      switch(indexPath.row) {
        case 0:
          return CellKindBarcode;
        case 1:
          return CellKindPIN;
        default:
          @throw NSInvalidArgumentException;
      }
    case 1:
      switch(indexPath.row) {
        case 0:
          return CellKindLoginLogout;
        default:
          @throw NSInvalidArgumentException;
      }
    default:
      @throw NSInvalidArgumentException;
  }
}

@interface NYPLSettingsAccountViewController () <NSURLSessionDelegate>

@property (nonatomic) UITextField *barcodeTextField;
@property (nonatomic, copy) void (^completionHandler)();
@property (nonatomic) BOOL hiddenPIN;
@property (nonatomic) UITableViewCell *loginLogoutCell;
@property (nonatomic) UITextField *PINTextField;
@property (nonatomic) NSURLSession *session;
@property (nonatomic) UIView *shieldView;

@end

@implementation NYPLSettingsAccountViewController

#pragma mark NSObject

- (instancetype)init
{
  self = [super initWithStyle:UITableViewStyleGrouped];
  if(!self) return nil;
  
  self.title = NSLocalizedString(@"Library Card", nil);
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(accountDidChange)
   name:NYPLAccountDidChangeNotification
   object:nil];
  
  NSURLSessionConfiguration *const configuration =
    [NSURLSessionConfiguration ephemeralSessionConfiguration];
  
  configuration.timeoutIntervalForResource = 5.0;
  
  self.session = [NSURLSession
                  sessionWithConfiguration:configuration
                  delegate:self
                  delegateQueue:[NSOperationQueue mainQueue]];
  
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
  
  self.barcodeTextField = [[UITextField alloc] initWithFrame:CGRectZero];
  self.barcodeTextField.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                            UIViewAutoresizingFlexibleHeight);
  self.barcodeTextField.font = [UIFont systemFontOfSize:17];
  self.barcodeTextField.placeholder = NSLocalizedString(@"Barcode", nil);
  self.barcodeTextField.keyboardType = UIKeyboardTypeNumberPad;
  [self.barcodeTextField
   addTarget:self
   action:@selector(textFieldsDidChange)
   forControlEvents:UIControlEventEditingChanged];
  
  self.PINTextField = [[UITextField alloc] initWithFrame:CGRectZero];
  self.PINTextField.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                        UIViewAutoresizingFlexibleHeight);
  self.PINTextField.font = [UIFont systemFontOfSize:17];
  self.PINTextField.placeholder = NSLocalizedString(@"PIN", nil);
  self.PINTextField.keyboardType = UIKeyboardTypeNumberPad;
  [self.PINTextField
   addTarget:self
   action:@selector(textFieldsDidChange)
   forControlEvents:UIControlEventEditingChanged];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  self.hiddenPIN = YES;
  
  [self accountDidChange];
  
  [self.tableView reloadData];
}

#pragma mark UITableViewDelegate

- (void)tableView:(__attribute__((unused)) UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *const)indexPath
{
  switch(CellKindFromIndexPath(indexPath)) {
    case CellKindBarcode:
      [self.barcodeTextField becomeFirstResponder];
      return;
    case CellKindPIN:
      [self.PINTextField becomeFirstResponder];
      return;
    case CellKindLoginLogout:
      [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
      if([[NYPLAccount sharedAccount] hasBarcodeAndPIN]) {
        [[[UIAlertView alloc]
          initWithTitle:NSLocalizedString(@"LogOut", nil)
          message:NSLocalizedString(@"SettingsAccountViewControllerLogoutMessage", nil)
          delegate:self
          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
          otherButtonTitles:NSLocalizedString(@"LogOut", nil), nil]
         show];
      } else {
        [self logIn];
      }
  }
}

#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(__attribute__((unused)) UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *const)indexPath
{
  // This is the amount of horizontal padding Apple uses around the titles in cells by default.
  CGFloat const padding = 16;
  
  switch(CellKindFromIndexPath(indexPath)) {
    case CellKindBarcode: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      {
        CGRect frame = cell.contentView.bounds;
        frame.origin.x += padding;
        frame.size.width -= padding * 2;
        self.barcodeTextField.frame = frame;
        [cell.contentView addSubview:self.barcodeTextField];
      }
      return cell;
    }
    case CellKindPIN: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      {
        CGRect frame = cell.contentView.bounds;
        frame.origin.x += padding;
        frame.size.width -= padding * 2;
        self.PINTextField.frame = frame;
        [cell.contentView addSubview:self.PINTextField];
      }
      return cell;
    }
    case CellKindLoginLogout: {
      if(!self.loginLogoutCell) {
        self.loginLogoutCell = [[UITableViewCell alloc]
                                initWithStyle:UITableViewCellStyleDefault
                                reuseIdentifier:nil];
        self.loginLogoutCell.textLabel.font = [UIFont systemFontOfSize:17];
      }
      [self updateLoginLogoutCellAppearance];
      return self.loginLogoutCell;
    }
  }
}

- (NSInteger)numberOfSectionsInTableView:(__attribute__((unused)) UITableView *)tableView
{
  return 2;
}

- (NSInteger)tableView:(__attribute__((unused)) UITableView *)tableView
 numberOfRowsInSection:(NSInteger const)section
{
  switch(section) {
    case 0:
      return 2;
    case 1:
      return 1;
    default:
      @throw NSInternalInconsistencyException;
  }
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *const)alertView
didDismissWithButtonIndex:(NSInteger const)buttonIndex
{
  if(buttonIndex == alertView.firstOtherButtonIndex) {
    [[NYPLMyBooksDownloadCenter sharedDownloadCenter] reset];
    [[NYPLBookRegistry sharedRegistry] reset];
    [[NYPLAccount sharedAccount] removeBarcodeAndPIN];
  }
  
  [self.tableView reloadData];
}

#pragma mark NSURLSessionDelegate

- (void)URLSession:(__attribute__((unused)) NSURLSession *)session
              task:(__attribute__((unused)) NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *const)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                             NSURLCredential *credential))completionHandler
{
  if(challenge.previousFailureCount) {
    completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
  } else {
    completionHandler(NSURLSessionAuthChallengeUseCredential,
                      [NSURLCredential
                       credentialWithUser:self.barcodeTextField.text
                       password:self.PINTextField.text
                       persistence:NSURLCredentialPersistenceNone]);
  }
}

#pragma mark -

- (void)didSelectReveal
{
  self.hiddenPIN = NO;
  [self.tableView reloadData];
}

- (void)accountDidChange
{
  if([NYPLAccount sharedAccount].hasBarcodeAndPIN) {
    self.barcodeTextField.text = [NYPLAccount sharedAccount].barcode;
    self.barcodeTextField.enabled = NO;
    self.barcodeTextField.textColor = [UIColor grayColor];
    self.PINTextField.text = [NYPLAccount sharedAccount].PIN;
    self.PINTextField.enabled = NO;
    self.PINTextField.textColor = [UIColor grayColor];
  } else {
    self.barcodeTextField.text = nil;
    self.barcodeTextField.enabled = YES;
    self.barcodeTextField.textColor = [UIColor blackColor];
    self.PINTextField.text = nil;
    self.PINTextField.enabled = YES;
    self.PINTextField.textColor = [UIColor blackColor];
  }
  
  [self updateLoginLogoutCellAppearance];
}

- (void)updateLoginLogoutCellAppearance
{
  if([[NYPLAccount sharedAccount] hasBarcodeAndPIN]) {
    self.loginLogoutCell.textLabel.text = NSLocalizedString(@"LogOut", nil);
    self.loginLogoutCell.textLabel.textColor = [NYPLConfiguration mainColor];
  } else {
    self.loginLogoutCell.textLabel.text = NSLocalizedString(@"LogIn", nil);
    BOOL const canLogIn =
      ([self.barcodeTextField.text
        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length &&
       [self.PINTextField.text
        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length);
    if(canLogIn) {
      self.loginLogoutCell.userInteractionEnabled = YES;
      self.loginLogoutCell.textLabel.textColor = [NYPLConfiguration mainColor];
    } else {
      self.loginLogoutCell.userInteractionEnabled = NO;
      self.loginLogoutCell.textLabel.textColor = [UIColor lightGrayColor];
    }
  }
}

- (void)logIn
{
  assert(self.barcodeTextField.text.length > 0);
  assert(self.PINTextField.text.length > 0);
  
  [self setShieldEnabled:YES];
  
  [self validateCredentials];
}

- (void)validateCredentials
{
  NSMutableURLRequest *const request =
  [NSMutableURLRequest requestWithURL:[NYPLConfiguration loanURL]];
  
  request.HTTPMethod = @"HEAD";
  
  NSURLSessionDataTask *const task =
  [self.session
   dataTaskWithRequest:request
   completionHandler:^(__attribute__((unused)) NSData *data,
                       NSURLResponse *const response,
                       NSError *const error) {
     
     [self setShieldEnabled:NO];
     
     if(error.code == NSURLErrorNotConnectedToInternet) {
       [[[UIAlertView alloc]
         initWithTitle:NSLocalizedString(@"SettingsCredentialViewControllerLoginFailed", nil)
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
         initWithTitle:NSLocalizedString(@"SettingsCredentialViewControllerLoginFailed", nil)
         message:NSLocalizedString(@"SettingsCredentialViewControllerInvalidCredentials", nil)
         delegate:nil
         cancelButtonTitle:nil
         otherButtonTitles:NSLocalizedString(@"OK", nil), nil]
        show];
       self.PINTextField.text = @"";
       [self textFieldsDidChange];
       [self.PINTextField becomeFirstResponder];
       return;
     }
     
     if(error.code == NSURLErrorTimedOut) {
       [[[UIAlertView alloc]
         initWithTitle:NSLocalizedString(@"SettingsCredentialViewControllerLoginFailed", nil)
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
       [[NYPLAccount sharedAccount] setBarcode:self.barcodeTextField.text
                                           PIN:self.PINTextField.text];
       [self dismissViewControllerAnimated:YES completion:^{}];
       void (^handler)() = self.completionHandler;
       self.completionHandler = nil;
       if(handler) handler();
       [[NYPLBookRegistry sharedRegistry] syncWithCompletionHandler:nil];
       return;
     }
     
     NYPLLOG(@"Encountered unexpected error after authenticating.");
     
     [[[UIAlertView alloc]
       initWithTitle:NSLocalizedString(@"SettingsCredentialViewControllerLoginFailed", nil)
       message:NSLocalizedString(@"UnknownRequestError", nil)
       delegate:nil
       cancelButtonTitle:nil
       otherButtonTitles:NSLocalizedString(@"OK", nil), nil]
      show];
   }];
  
  [task resume];
}

- (void)setShieldEnabled:(BOOL)enabled
{
  if(enabled && !self.shieldView) {
    [self.barcodeTextField resignFirstResponder];
    [self.PINTextField resignFirstResponder];
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
    [activityIndicatorView integralizeFrame];
    [activityIndicatorView startAnimating];
    [self.view addSubview:self.shieldView];
  } else {
    [self.shieldView removeFromSuperview];
    self.shieldView = nil;
  }
}

- (void)textFieldsDidChange
{
  [self updateLoginLogoutCellAppearance];
}

@end
