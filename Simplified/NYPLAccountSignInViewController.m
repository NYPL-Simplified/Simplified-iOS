@import LocalAuthentication;
@import NYPLCardCreator;

#import "SimplyE-Swift.h"

#import "NYPLAccount.h"
#import "NYPLAlertController.h"
#import "NYPLAppDelegate.h"
#import "NYPLBasicAuth.h"
#import "NYPLBookCoverRegistry.h"
#import "NYPLBookRegistry.h"
#import "NYPLConfiguration.h"
#import "NYPLLinearView.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLReachability.h"
#import "NYPLSettings.h"
#import "NYPLAccountSignInViewController.h"
#import "NYPLSettingsEULAViewController.h"
#import "NYPLRootTabBarController.h"
#import "UIView+NYPLViewAdditions.h"
#import <PureLayout/PureLayout.h>
@import CoreLocation;


#if defined(FEATURE_DRM_CONNECTOR)
#import <ADEPT/ADEPT.h>
#endif

typedef NS_ENUM(NSInteger, CellKind) {
  CellKindBarcode,
  CellKindPIN,
  CellKindLogInSignOut,
  CellKindRegistration,
  CellKindEULA
};

typedef NS_ENUM(NSInteger, Section) {
  SectionBarcodePin = 0,
  SectionEULA = 1,
  SectionLoginLogout = 2,
  SectionRegistration = 3
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
          return CellKindEULA;
        default:
          @throw NSInvalidArgumentException;
      }
    case 2:
      switch(indexPath.row) {
        case 0:
          return CellKindLogInSignOut;
        default:
          @throw NSInvalidArgumentException;
      }
    case 3:
      return CellKindRegistration;
    default:
      @throw NSInvalidArgumentException;
  }
}

@interface NYPLAccountSignInViewController () <NSURLSessionDelegate, UITextFieldDelegate, UIAlertViewDelegate>

@property (nonatomic) BOOL isLoggingInAfterSignUp;
@property (nonatomic) BOOL isCurrentlySigningIn;
@property (nonatomic) UITextField *barcodeTextField;
@property (nonatomic) UIButton *barcodeScanButton;
@property (nonatomic, copy) void (^completionHandler)();
@property (nonatomic) BOOL hiddenPIN;
@property (nonatomic) UITableViewCell *eulaCell;
@property (nonatomic) UITableViewCell *logInSignOutCell;
@property (nonatomic) UITextField *PINTextField;
@property (nonatomic) NSURLSession *session;
@property (nonatomic) UIButton *PINShowHideButton;
@property (nonatomic) bool rotated;

@end

@implementation NYPLAccountSignInViewController

#pragma mark NSObject

- (instancetype)init
{
  self = [super initWithStyle:UITableViewStyleGrouped];
  if(!self) return nil;
  
  self.title = NSLocalizedString(@"SignIn", nil);

  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(accountDidChange)
   name:NYPLAccountDidChangeNotification
   object:nil];
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(keyboardDidShow:)
   name:UIKeyboardWillShowNotification
   object:nil];
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(willResignActive)
   name:UIApplicationWillResignActiveNotification
   object:nil];

  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(willEnterForeground)
   name:UIApplicationWillEnterForegroundNotification
   object:nil];
  
  NSURLSessionConfiguration *const configuration =
    [NSURLSessionConfiguration ephemeralSessionConfiguration];
  
  configuration.timeoutIntervalForResource = 10.0;
  
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
  self.barcodeTextField.delegate = self;
  self.barcodeTextField.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                            UIViewAutoresizingFlexibleHeight);
  self.barcodeTextField.font = [UIFont systemFontOfSize:17];
  self.barcodeTextField.placeholder = NSLocalizedString(@"BarcodeOrUsername", nil);
  self.barcodeTextField.keyboardType = UIKeyboardTypeASCIICapable;
  self.barcodeTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
  self.barcodeTextField.autocorrectionType = UITextAutocorrectionTypeNo;
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
  self.PINTextField.secureTextEntry = YES;
  self.PINTextField.delegate = self;
  [self.PINTextField
   addTarget:self
   action:@selector(textFieldsDidChange)
   forControlEvents:UIControlEventEditingChanged];

  self.PINShowHideButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.PINShowHideButton setTitle:NSLocalizedString(@"Show", nil) forState:UIControlStateNormal];
  [self.PINShowHideButton sizeToFit];
  [self.PINShowHideButton addTarget:self action:@selector(PINShowHideSelected)
                   forControlEvents:UIControlEventTouchUpInside];
  self.PINTextField.rightView = self.PINShowHideButton;
  self.PINTextField.rightViewMode = UITextFieldViewModeAlways;
  
  Account *currentAccount = [[NYPLSettings sharedSettings] currentAccount];

  if (currentAccount.supportsBarcodeScanner) {
    self.barcodeScanButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.barcodeScanButton setImage:[UIImage imageNamed:@"ic_camera"] forState:UIControlStateNormal];
    [self.barcodeScanButton sizeToFit];
    [self.barcodeScanButton addTarget:self action:@selector(scanLibraryCard)
                     forControlEvents:UIControlEventTouchUpInside];
    
    self.barcodeTextField.rightView = self.barcodeScanButton;
    self.barcodeTextField.rightViewMode = UITextFieldViewModeAlways;
  }

  
  
  self.logInSignOutCell = [[UITableViewCell alloc]
                           initWithStyle:UITableViewCellStyleDefault
                           reuseIdentifier:nil];
  
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"EULA"
                                                                            style:UIBarButtonItemStylePlain
                                                                           target:self
                                                                           action:@selector(showEULA)];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  // The new credentials are not yet saved when logging in after signup. As such,
  // reloading the table would lose the values in the barcode and PIN fields.
  if(!self.isLoggingInAfterSignUp) {
    self.hiddenPIN = YES;
    [self accountDidChange];
    [self.tableView reloadData];
    [self updateShowHidePINState];
  }
}

#if defined(FEATURE_DRM_CONNECTOR)
- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  if (![[NYPLADEPT sharedInstance] isUserAuthorized:[[NYPLAccount sharedAccount] userID] withDevice:[[NYPLAccount sharedAccount] deviceID]]) {
    if ([[NYPLAccount sharedAccount] hasBarcodeAndPIN] && !self.isCurrentlySigningIn) {
      self.barcodeTextField.text = [NYPLAccount sharedAccount].barcode;
      self.PINTextField.text = [NYPLAccount sharedAccount].PIN;
      [self logIn];
    }
  }
}
#endif

#pragma mark UITableViewDelegate

- (void)tableView:(__attribute__((unused)) UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *const)indexPath
{
  switch(CellKindFromIndexPath(indexPath)) {
    case CellKindBarcode:
      [self.barcodeTextField becomeFirstResponder];
      break;
    case CellKindPIN:
      [self.PINTextField becomeFirstResponder];
      break;
    case CellKindEULA: {
      UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
      Account *currentAccount = [[NYPLSettings sharedSettings] currentAccount];
      if (currentAccount.eulaIsAccepted) {
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CheckboxOff"]];
        self.eulaCell.accessibilityLabel = NSLocalizedString(@"AccessibilityEULAUnchecked", nil);
        self.eulaCell.accessibilityHint = NSLocalizedString(@"AccessibilityEULAHintUnchecked", nil);
        currentAccount.eulaIsAccepted = NO;
      } else {
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CheckboxOn"]];
        self.eulaCell.accessibilityLabel = NSLocalizedString(@"AccessibilityEULAChecked", nil);
        self.eulaCell.accessibilityHint = NSLocalizedString(@"AccessibilityEULAHintChecked", nil);
        currentAccount.eulaIsAccepted = YES;
      }
      [self updateLoginLogoutCellAppearance];
      break;
    }
    case CellKindLogInSignOut:
      [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
      [self logIn];
      break;
    case CellKindRegistration: {
      [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
      
      Account *currentAccount = [[NYPLSettings sharedSettings] currentAccount];
      if (currentAccount.supportsCardCreator) {
        __weak NYPLAccountSignInViewController *const weakSelf = self;
        CardCreatorConfiguration *const configuration =
          [[CardCreatorConfiguration alloc]
           initWithEndpointURL:[APIKeys cardCreatorEndpointURL]
           endpointVersion:[APIKeys cardCreatorVersion]
           endpointUsername:[APIKeys cardCreatorUsername]
           endpointPassword:[APIKeys cardCreatorPassword]
           requestTimeoutInterval:20.0
           completionHandler:^(NSString *const username, NSString *const PIN, BOOL const userInitiated) {
             if (userInitiated) {
               // Dismiss CardCreator & SignInVC when user finishes Credential Review
               [weakSelf dismissViewControllerAnimated:YES completion:nil];
               [weakSelf dismissViewControllerAnimated:YES completion:nil];
             } else {
               weakSelf.barcodeTextField.text = username;
               weakSelf.PINTextField.text = PIN;
               [weakSelf updateLoginLogoutCellAppearance];
               self.isLoggingInAfterSignUp = YES;
               [weakSelf logIn];
             }
           }];
        
        UINavigationController *const navigationController =
          [CardCreator initialNavigationControllerWithConfiguration:configuration];
        navigationController.navigationBar.topItem.leftBarButtonItem =
          [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                           style:UIBarButtonItemStylePlain
                                          target:self
                                          action:@selector(didSelectCancelForSignUp)];
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:navigationController animated:YES completion:nil];
      }
      else
      {
        
        RemoteHTMLViewController *webViewController = [[RemoteHTMLViewController alloc] initWithURL:[[NSURL alloc] initWithString:currentAccount.cardCreatorUrl] title:@"eCard" failureMessage:NSLocalizedString(@"SettingsConnectionFailureMessage", nil)];
        
        UINavigationController *const navigationController = [[UINavigationController alloc] initWithRootViewController:webViewController];
       
        navigationController.navigationBar.topItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil)
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(didSelectCancelForSignUp)];
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:navigationController animated:YES completion:nil];

        
      }
      break;
    }
  }
}

- (void)didSelectCancelForSignUp
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)verifyLocationServicesWithHandler:(void(^)(void))handler
{
  CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
  
  switch (status) {
    case kCLAuthorizationStatusAuthorizedAlways:
      if (handler) handler();
      break;
    case kCLAuthorizationStatusAuthorizedWhenInUse:
      if (handler) handler();
      break;
    case kCLAuthorizationStatusDenied:
    {
      UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Location", nil)
                                                                               message:NSLocalizedString(@"LocationRequiredMessage", nil)
                                                                        preferredStyle:UIAlertControllerStyleAlert];
      
      UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Settings", nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                           if (action)[UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                                                         }];

      UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                           style:UIAlertActionStyleDestructive
                                                         handler:nil];
      
      [alertController addAction:settingsAction];
      [alertController addAction:cancelAction];
      
      [self presentViewController:alertController
                         animated:NO
                       completion:nil];
      
      break;
    }
    case kCLAuthorizationStatusRestricted:
      if (handler) handler();
      break;
    case kCLAuthorizationStatusNotDetermined:
      if (handler) handler();
      break;
  }
}

#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(__attribute__((unused)) UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *const)indexPath
{
  switch(CellKindFromIndexPath(indexPath)) {
    case CellKindBarcode: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      {
        [cell.contentView addSubview:self.barcodeTextField];
        [self.barcodeTextField autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        [self.barcodeTextField autoPinEdgeToSuperviewMargin:ALEdgeLeft];
        [self.barcodeTextField autoPinEdgeToSuperviewMargin:ALEdgeRight];
      }
      return cell;
    }
    case CellKindPIN: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      {
        [cell.contentView addSubview:self.PINTextField];
        [self.PINTextField autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        [self.PINTextField autoPinEdgeToSuperviewMargin:ALEdgeLeft];
        [self.PINTextField autoPinEdgeToSuperviewMargin:ALEdgeRight];
      }
      return cell;
    }
    case CellKindEULA: {
      self.eulaCell = [[UITableViewCell alloc]
                       initWithStyle:UITableViewCellStyleDefault
                       reuseIdentifier:nil];
      Account *currentAccount = [[NYPLSettings sharedSettings] currentAccount];
      if (currentAccount.eulaIsAccepted) {
        self.eulaCell.accessoryView = [[UIImageView alloc] initWithImage:
                                       [UIImage imageNamed:@"CheckboxOn"]];
        self.eulaCell.accessibilityLabel = NSLocalizedString(@"AccessibilityEULAChecked", nil);
        self.eulaCell.accessibilityHint = NSLocalizedString(@"AccessibilityEULAHintChecked", nil);
      } else {
        self.eulaCell.accessoryView = [[UIImageView alloc] initWithImage:
                                       [UIImage imageNamed:@"CheckboxOff"]];
        self.eulaCell.accessibilityLabel = NSLocalizedString(@"AccessibilityEULAUnchecked", nil);
        self.eulaCell.accessibilityHint = NSLocalizedString(@"AccessibilityEULAHintUnchecked", nil);
      }
      self.eulaCell.selectionStyle = UITableViewCellSelectionStyleNone;
      self.eulaCell.textLabel.font = [UIFont systemFontOfSize:13];
      self.eulaCell.textLabel.text = NSLocalizedString(@"SettingsAccountEULACheckbox", @"Statement letting a user know that they must agree to the User Agreement terms.");
      self.eulaCell.textLabel.numberOfLines = 2;
      return self.eulaCell;
    }
    case CellKindLogInSignOut: {
      self.logInSignOutCell.textLabel.font = [UIFont systemFontOfSize:17];
      [self updateLoginLogoutCellAppearance];
      return self.logInSignOutCell;
    }
    case CellKindRegistration: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleValue1
                                     reuseIdentifier:nil];
      cell.textLabel.font = [UIFont systemFontOfSize:17];
      cell.textLabel.text = NSLocalizedString(@"SettingsAccountRegistrationTitle", @"Title for registration. Asking the user if they already have a library card.");
      cell.detailTextLabel.font = [UIFont systemFontOfSize:17];
      cell.detailTextLabel.text = NSLocalizedString(@"SignUp", nil);
      cell.detailTextLabel.textColor = [NYPLConfiguration mainColor];
      return cell;
    }
  }
}

- (BOOL)registrationIsPossible
{
  return ([NYPLConfiguration cardCreationEnabled] &&
          ([[AccountsManager sharedInstance] currentAccount].supportsCardCreator || [[AccountsManager sharedInstance] currentAccount].cardCreatorUrl) &&
          ![[NYPLAccount sharedAccount] hasBarcodeAndPIN]);
}

- (NSInteger)numberOfSectionsInTableView:(__attribute__((unused)) UITableView *)tableView
{
  if([self registrationIsPossible]) {
    // registration is possible.
    return 4;
  } else {
    // no Registration is possible.
    return 3;
  }
}

- (NSInteger)tableView:(__attribute__((unused)) UITableView *)tableView
 numberOfRowsInSection:(NSInteger const)section
{
  switch(section) {
    case SectionBarcodePin:
      return 2;
    case SectionEULA:
      return 1;
    case SectionLoginLogout:
      return 1;
    case SectionRegistration:
      return 1;
    default:
      @throw NSInternalInconsistencyException;
  }
}

- (BOOL)textFieldShouldBeginEditing:(__unused UITextField *)textField
{
  return ![[NYPLAccount sharedAccount] hasBarcodeAndPIN];
}

#pragma mark NSURLSessionDelegate

- (void)URLSession:(__attribute__((unused)) NSURLSession *)session
              task:(__attribute__((unused)) NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *const)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                             NSURLCredential *credential))completionHandler
{
  NYPLBasicAuthCustomHandler(challenge,
                             completionHandler,
                             self.barcodeTextField.text,
                             self.PINTextField.text);
}

#pragma mark UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string
{
  if(![string canBeConvertedToEncoding:NSASCIIStringEncoding]) {
    return NO;
  }
  
  if(textField == self.barcodeTextField) {
    // Barcodes are numeric and usernames are alphanumeric.
    if([string stringByTrimmingCharactersInSet:[NSCharacterSet alphanumericCharacterSet]].length > 0) {
      return NO;
    }
    
    // Usernames cannot be longer than 25 characters.
    if([textField.text stringByReplacingCharactersInRange:range withString:string].length > 25) {
      return NO;
    }
  }
  
  if(textField == self.PINTextField) {
    if([string stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]].length > 0) {
      return NO;
    }
    
    if([textField.text stringByReplacingCharactersInRange:range withString:string].length > 4) {
      return NO;
    }
  }

  return YES;
}


#pragma mark -

- (void)didSelectReveal
{
  self.hiddenPIN = NO;
  [self.tableView reloadData];
}

- (void)PINShowHideSelected
{
  if(self.PINTextField.text.length > 0 && self.PINTextField.secureTextEntry) {
    LAContext *const context = [[LAContext alloc] init];
    if([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:NULL]) {
      [context evaluatePolicy:LAPolicyDeviceOwnerAuthentication
              localizedReason:NSLocalizedString(@"SettingsAccountViewControllerAuthenticationReason", nil)
                        reply:^(__unused BOOL success,
                                __unused NSError *_Nullable error) {
                          if(success) {
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                              [self togglePINShowHideState];
                            }];
                          }
                        }];
    } else {
      [self togglePINShowHideState];
    }
  } else {
    [self togglePINShowHideState];
  }
}

- (void)togglePINShowHideState
{
  self.PINTextField.secureTextEntry = !self.PINTextField.secureTextEntry;
  NSString *title = self.PINTextField.secureTextEntry ? @"Show" : @"Hide";
  [self.PINShowHideButton setTitle:NSLocalizedString(title, nil) forState:UIControlStateNormal];
  [self.PINShowHideButton sizeToFit];
  [self.tableView reloadData];
}

- (void)accountDidChange
{
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    if([NYPLAccount sharedAccount].hasBarcodeAndPIN) {
      self.barcodeTextField.text = [NYPLAccount sharedAccount].barcode;
      self.barcodeTextField.enabled = NO;
      self.barcodeTextField.textColor = [UIColor grayColor];
      self.PINTextField.text = [NYPLAccount sharedAccount].PIN;
      self.PINTextField.textColor = [UIColor grayColor];
    } else {
      self.barcodeTextField.text = nil;
      self.barcodeTextField.enabled = YES;
      self.barcodeTextField.textColor = [UIColor blackColor];
      self.PINTextField.text = nil;
      self.PINTextField.textColor = [UIColor blackColor];
    }
    
    [self.tableView reloadData];
    
    [self updateLoginLogoutCellAppearance];
  }];
}

- (void)showEULA
{
  Account *currentAccount = [[AccountsManager sharedInstance] currentAccount];
  UIViewController *eulaViewController = [[NYPLSettingsEULAViewController alloc] initWithAccount:currentAccount];
  UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:eulaViewController];
  [self.navigationController presentViewController:navVC animated:YES completion:nil];
}

- (void)updateLoginLogoutCellAppearance
{
  if (self.isCurrentlySigningIn) {
    return;
  }
  if([[NYPLAccount sharedAccount] hasBarcodeAndPIN]) {
    self.logInSignOutCell.textLabel.text = NSLocalizedString(@"SignOut", nil);
    self.logInSignOutCell.textLabel.textAlignment = NSTextAlignmentCenter;
    self.logInSignOutCell.textLabel.textColor = [NYPLConfiguration mainColor];
    self.logInSignOutCell.userInteractionEnabled = YES;
    self.eulaCell.userInteractionEnabled = NO;
  } else {
    self.eulaCell.userInteractionEnabled = YES;
    self.logInSignOutCell.textLabel.text = NSLocalizedString(@"LogIn", nil);
    Account *currentAccount = [[NYPLSettings sharedSettings] currentAccount];
    BOOL const canLogIn =
      ([self.barcodeTextField.text
        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length &&
       [self.PINTextField.text
        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length) &&
       currentAccount.eulaIsAccepted;
    if(canLogIn) {
      self.logInSignOutCell.userInteractionEnabled = YES;
      self.logInSignOutCell.textLabel.textColor = [NYPLConfiguration mainColor];
    } else {
      self.logInSignOutCell.userInteractionEnabled = NO;
      self.logInSignOutCell.textLabel.textColor = [UIColor lightGrayColor];
    }
  }
}

- (void)logIn
{
  assert(self.barcodeTextField.text.length > 0);
  assert(self.PINTextField.text.length > 0);
  
  [self.barcodeTextField resignFirstResponder];
  [self.PINTextField resignFirstResponder];

  [self setActivityTitleWithText:NSLocalizedString(@"Verifying", nil)];
  
  [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
  
  [self validateCredentials];
}

- (void)setActivityTitleWithText:(NSString *)text
{
  UIActivityIndicatorView *const activityIndicatorView =
  [[UIActivityIndicatorView alloc]
   initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  
  [activityIndicatorView startAnimating];
  
  UILabel *const titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  titleLabel.text = text;
  titleLabel.font = [UIFont systemFontOfSize:17];
  [titleLabel sizeToFit];
  
  // This view is used to keep the title label centered as in Apple's Settings application.
  UIView *const rightPaddingView = [[UIView alloc] initWithFrame:activityIndicatorView.bounds];
  
  NYPLLinearView *const linearView = [[NYPLLinearView alloc] init];
  linearView.tag = 1;
  linearView.contentVerticalAlignment = NYPLLinearViewContentVerticalAlignmentMiddle;
  linearView.padding = 5.0;
  [linearView addSubview:activityIndicatorView];
  [linearView addSubview:titleLabel];
  [linearView addSubview:rightPaddingView];
  [linearView sizeToFit];
  
  self.logInSignOutCell.textLabel.text = nil;
  [self.logInSignOutCell.contentView addSubview:linearView];
  linearView.center = self.logInSignOutCell.contentView.center;
}

- (void)removeActivityTitle {
  UIView *view = [self.logInSignOutCell.contentView viewWithTag:1];
  [view removeFromSuperview];
}

- (void)validateCredentials
{
  NSMutableURLRequest *const request =
    [NSMutableURLRequest requestWithURL:[NYPLConfiguration loanURL]];
  
  // Necessary to support longer login times when using usernames.
  request.timeoutInterval = 20.0;
  
  request.HTTPMethod = @"HEAD";
  
  self.isCurrentlySigningIn = YES;
  NSURLSessionDataTask *const task =
    [self.session
     dataTaskWithRequest:request
     completionHandler:^(__attribute__((unused)) NSData *data,
                         NSURLResponse *const response,
                         NSError *const error) {
       
       self.isCurrentlySigningIn = NO;
       // This cast is always valid according to Apple's documentation for NSHTTPURLResponse.
       NSInteger const statusCode = ((NSHTTPURLResponse *) response).statusCode;
       
       // Success.
       if(statusCode == 200) {
         [self authorizationAttemptDidFinish:YES error:nil];
         self.isLoggingInAfterSignUp = NO;
         return;
       }
       
       [self removeActivityTitle];
       [[UIApplication sharedApplication] endIgnoringInteractionEvents];
       
       if (error.code == NSURLErrorCancelled) {
         // We cancelled the request when asked to answer the server's challenge a second time
         // because we don't have valid credentials.
         self.PINTextField.text = @"";
         [self textFieldsDidChange];
         [self.PINTextField becomeFirstResponder];
       }
       
       if (statusCode == 401) {
         NSError *error401 = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
         [self showLoginAlertWithError:error401];
         return;
       }
       [self showLoginAlertWithError:error];
       
     }];
  
  [task resume];
}

- (void)showLoginAlertWithError:(NSError *)error
{
  [[NYPLRootTabBarController sharedController] safelyPresentViewController:
   [NYPLAlertController alertWithTitle:@"SettingsAccountViewControllerLoginFailed" error:error]
                                                                  animated:YES
                                                                completion:nil];
  [self updateLoginLogoutCellAppearance];
}

- (void)textFieldsDidChange
{
  [self updateLoginLogoutCellAppearance];
}

- (void)keyboardDidShow:(NSNotification *const)notification
{
  // This nudges the scroll view up slightly so that the log in button is clearly visible even on
  // older 3:2 iPhone displays. I wish there were a more general way to do this, but this does at
  // least work very well.
  
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
      CGSize const keyboardSize =
      [[notification userInfo][UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
      CGRect visibleRect = self.view.frame;
      visibleRect.size.height -= keyboardSize.height + self.tableView.contentInset.top;
      if(!CGRectContainsPoint(visibleRect,
                              CGPointMake(0, CGRectGetMaxY(self.logInSignOutCell.frame)))) {
        // We use an explicit animation block here because |setContentOffset:animated:| does not seem
        // to work at all.
        [UIView animateWithDuration:0.25 animations:^{
          [self.tableView setContentOffset:CGPointMake(0, -self.tableView.contentInset.top + 20)];
        }];
      }
    }
  }];
}

+ (void)
requestCredentialsUsingExistingBarcode:(BOOL const)useExistingBarcode
authorizeImmediately:(BOOL)authorizeImmediately
completionHandler:(void (^)())handler
{
  NYPLAccountSignInViewController *const accountViewController = [[self alloc] init];
  
  accountViewController.completionHandler = handler;
  
  // Tell |accountViewController| to create its text fields so we can set their properties.
  [accountViewController view];
  
  if(useExistingBarcode) {
    NSString *const barcode = [NYPLAccount sharedAccount].barcode;
    if(!barcode) {
      @throw NSInvalidArgumentException;
    }
    accountViewController.barcodeTextField.text = barcode;
  } else {
    accountViewController.barcodeTextField.text = @"";
  }
  
  accountViewController.PINTextField.text = @"";
  
  UIBarButtonItem *const cancelBarButtonItem =
    [[UIBarButtonItem alloc]
     initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
     target:accountViewController
     action:@selector(didSelectCancel)];
  
  accountViewController.navigationItem.leftBarButtonItem = cancelBarButtonItem;
  
  UIViewController *const viewController = [[UINavigationController alloc]
                                            initWithRootViewController:accountViewController];
  viewController.modalPresentationStyle = UIModalPresentationFormSheet;
  
  [[NYPLRootTabBarController sharedController]
   safelyPresentViewController:viewController 
   animated:YES
   completion:nil];
  
  if (authorizeImmediately && [NYPLAccount sharedAccount].hasBarcodeAndPIN) {
    accountViewController.PINTextField.text = [NYPLAccount sharedAccount].PIN;
    [accountViewController logIn];
  } else {
    if(useExistingBarcode) {
      [accountViewController.PINTextField becomeFirstResponder];
    } else {
      [accountViewController.barcodeTextField becomeFirstResponder];
    }
  }
}

+ (void)requestCredentialsUsingExistingBarcode:(BOOL)useExistingBarcode
                             completionHandler:(void (^)())handler
{
  [self requestCredentialsUsingExistingBarcode:useExistingBarcode authorizeImmediately:NO completionHandler:handler];
}

+ (void)authorizeUsingExistingBarcodeAndPinWithCompletionHandler:(void (^)())handler
{
  [self requestCredentialsUsingExistingBarcode:YES authorizeImmediately:YES completionHandler:handler];
}

- (void)didSelectCancel
{
  [self.navigationController.presentingViewController
   dismissViewControllerAnimated:YES
   completion:nil];
}

- (void)authorizationAttemptDidFinish:(BOOL)success error:(NSError *)error
{
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [self removeActivityTitle];
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    
    if(success) {
      [[NYPLAccount sharedAccount] setBarcode:self.barcodeTextField.text
                                          PIN:self.PINTextField.text];
      if (!self.isLoggingInAfterSignUp) {
        [self dismissViewControllerAnimated:YES completion:nil];
      }
      void (^handler)() = self.completionHandler;
      self.completionHandler = nil;
      if(handler) handler();
      [[NSNotificationCenter defaultCenter] postNotificationName:NYPLSyncBeganNotification object:nil];
      [[NYPLBookRegistry sharedRegistry] syncWithCompletionHandler:^(BOOL __unused success) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NYPLSyncEndedNotification object:nil];
      }];

    } else {
      [[NSNotificationCenter defaultCenter] postNotificationName:NYPLSyncEndedNotification object:nil];
      [self showLoginAlertWithError:error];
    }
  }];
}

- (void)willResignActive
{
  if(!self.PINTextField.secureTextEntry) {
    [self togglePINShowHideState];
  }
}

- (void)updateShowHidePINState
{
  self.PINTextField.rightView.hidden = YES;
  
  // LAPolicyDeviceOwnerAuthentication is only on iOS >= 9.0
  if([NSProcessInfo processInfo].operatingSystemVersion.majorVersion >= 9) {
    LAContext *const context = [[LAContext alloc] init];
    if([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:NULL]) {
      self.PINTextField.rightView.hidden = NO;
    }
  }
}

- (void)willEnterForeground
{
  // We update the state again in case the user enabled or disabled an authentication mechanism.
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [self updateShowHidePINState];
  }];
}

@end
