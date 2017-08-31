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
#import "NYPLXML.h"
#import "NYPLOPDSFeed.h"
#import "UIView+NYPLViewAdditions.h"
#import "UIFont+NYPLSystemFontOverride.h"
#import <PureLayout/PureLayout.h>
@import CoreLocation;


#if defined(FEATURE_DRM_CONNECTOR)
#import <ADEPT/ADEPT.h>
#endif

typedef NS_ENUM(NSInteger, CellKind) {
  CellKindBarcode,
  CellKindPIN,
  CellKindLogInSignOut,
  CellKindRegistration
};

typedef NS_ENUM(NSInteger, Section) {
  SectionCredentials = 0,
  SectionRegistration = 1
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
        case 2:
          return CellKindLogInSignOut;
        default:
          @throw NSInvalidArgumentException;
      }
    case 1:
      switch(indexPath.row) {
        case 0:
          return CellKindRegistration;
        default:
          @throw NSInvalidArgumentException;
      }
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
@property (nonatomic) UITableViewCell *logInSignOutCell;
@property (nonatomic) UITextField *PINTextField;
@property (nonatomic) NSURLSession *session;
@property (nonatomic) UIButton *PINShowHideButton;
@property (nonatomic) bool rotated;
@property (nonatomic) Account *currentAccount;

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
  
  self.currentAccount = [[AccountsManager sharedInstance] currentAccount];
  
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
  if (self.currentAccount.authPasscodeAllowsLetters) {
    self.PINTextField.keyboardType = UIKeyboardTypeASCIICapable;
  } else {
    self.PINTextField.keyboardType = UIKeyboardTypeNumberPad;
  }
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
    case CellKindLogInSignOut: {
      self.logInSignOutCell.textLabel.font = [UIFont customBoldFontForTextStyle:UIFontTextStyleBody];
      [self updateLoginLogoutCellAppearance];
      return self.logInSignOutCell;
    }
    case CellKindRegistration: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleValue1
                                     reuseIdentifier:nil];
      cell.textLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
      cell.textLabel.text = NSLocalizedString(@"SettingsAccountRegistrationTitle", @"Title for registration. Asking the user if they already have a library card.");
      cell.detailTextLabel.font = [UIFont customBoldFontForTextStyle:UIFontTextStyleBody];
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
    return 2;
  } else {
    return 1;
  }
}

- (NSInteger)tableView:(__attribute__((unused)) UITableView *)tableView
 numberOfRowsInSection:(NSInteger const)section
{
  switch(section) {
    case SectionCredentials:
      return 3;
    case SectionRegistration:
      return 1;
    default:
      @throw NSInternalInconsistencyException;
  }
}

- (CGFloat)tableView:(UITableView *)__unused tableView heightForRowAtIndexPath:(NSIndexPath *)__unused indexPath {
  return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)__unused tableView heightForFooterInSection:(NSInteger)__unused section {
  return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)__unused tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)__unused indexPath {
  return 80;
}

- (CGFloat)tableView:(UITableView *)__unused tableView estimatedHeightForFooterInSection:(NSInteger)__unused section {
  return 80;
}

- (UIView *)tableView:(UITableView *)__unused tableView viewForFooterInSection:(NSInteger)section
{
  if (section == SectionCredentials) {
    UIView *container = [[UIView alloc] init];
    UILabel *footerLabel = [[UILabel alloc] init];
    footerLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleCaption1];
    footerLabel.textColor = [UIColor lightGrayColor];
    footerLabel.numberOfLines = 0;
    footerLabel.userInteractionEnabled = YES;

    NSMutableAttributedString *eulaString = [[NSMutableAttributedString alloc] initWithString:@"By signing in, you agree to the " attributes:nil];
    NSDictionary *linkAttributes = @{ NSForegroundColorAttributeName : [UIColor colorWithRed:0.05 green:0.4 blue:0.65 alpha:1.0],
                                      NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle) };
    NSMutableAttributedString *linkString = [[NSMutableAttributedString alloc] initWithString:@"End User License Agreement." attributes:linkAttributes];
    [eulaString appendAttributedString:linkString];

    footerLabel.attributedText = eulaString;
    [footerLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showEULA)]];

    [container addSubview:footerLabel];
    [footerLabel autoPinEdgeToSuperviewMargin:ALEdgeLeft];
    [footerLabel autoPinEdgeToSuperviewMargin:ALEdgeRight];
    [footerLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:8.0];
    [footerLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:8.0];

    return container;

  } else {
    return nil;
  }
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
    // Usernames are alphanumeric.
    if([string stringByTrimmingCharactersInSet:[NSCharacterSet alphanumericCharacterSet]].length > 0) {
      return NO;
    }
    
    // Usernames cannot be longer than 25 characters.
    if([textField.text stringByReplacingCharactersInRange:range withString:string].length > 25) {
      return NO;
    }
  }
  
  if(textField == self.PINTextField) {
    
    NSCharacterSet *charSet = [NSCharacterSet decimalDigitCharacterSet];
    bool alphanumericPin = self.currentAccount.authPasscodeAllowsLetters;
    bool containsNonNumericChar = [string stringByTrimmingCharactersInSet:charSet].length > 0;
    bool abovePinCharLimit = [textField.text stringByReplacingCharactersInRange:range withString:string].length > self.currentAccount.authPasscodeLength;
    
    // PIN's support numeric or alphanumeric.
    if (!alphanumericPin && containsNonNumericChar) {
      return NO;
    }
    // PIN's character limit. Zero is unlimited.
    if (self.currentAccount.authPasscodeLength == 0) {
      return YES;
    } else if (abovePinCharLimit) {
      return NO;
    }
  }

  return YES;
}

- (BOOL)textFieldShouldBeginEditing:(__unused UITextField *)textField
{
  return ![[NYPLAccount sharedAccount] hasBarcodeAndPIN];
}

#pragma mark Class Methods


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

#pragma mark -

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
  } else {
    self.logInSignOutCell.textLabel.text = NSLocalizedString(@"LogIn", nil);
    BOOL const canLogIn =
      ([self.barcodeTextField.text
        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length &&
       [self.PINTextField.text
        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length);
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
  
  request.timeoutInterval = 20.0;
  
  self.isCurrentlySigningIn = YES;
  NSURLSessionDataTask *const task =
    [self.session
     dataTaskWithRequest:request
     completionHandler:^(NSData *data,
                         NSURLResponse *const response,
                         NSError *const error) {
       
       self.isCurrentlySigningIn = NO;

       NSInteger const statusCode = ((NSHTTPURLResponse *) response).statusCode;
       
       if(statusCode == 200) {
         
#if defined(FEATURE_DRM_CONNECTOR)        

         NYPLXML *loansXML = [NYPLXML XMLWithData:data];
         NYPLOPDSFeed *loansFeed = [[NYPLOPDSFeed alloc] initWithXML:loansXML];
         
         if (loansFeed.licensor) {
           [[NYPLAccount sharedAccount] setLicensor:loansFeed.licensor];
         } else {
           NYPLLOG(@"Login Failed: No Licensor Token received or parsed from OPDS Loans feed");
           [self authorizationAttemptDidFinish:NO error:nil];
           return;
         }
         
         NSMutableArray *licensorItems = [[loansFeed.licensor[@"clientToken"] stringByReplacingOccurrencesOfString:@"\n" withString:@""] componentsSeparatedByString:@"|"].mutableCopy;
         NSString *tokenPassword = [licensorItems lastObject];
         [licensorItems removeLastObject];
         NSString *tokenUsername = [licensorItems componentsJoinedByString:@"|"];
         
         NYPLLOG(@"***DRM Auth/Activation Attempt***");
         NYPLLOG_F(@"\nLicensor: %@\n",loansFeed.licensor);
         NYPLLOG_F(@"Token Username: %@\n",tokenUsername);
         NYPLLOG_F(@"Token Password: %@\n",tokenPassword);
         
         [[NYPLADEPT sharedInstance]
          authorizeWithVendorID:[[NYPLAccount sharedAccount] licensor][@"vendor"]
          username:tokenUsername
          password:tokenPassword
          completion:^(BOOL success, NSError *error, NSString *deviceID, NSString *userID) {
            
            NYPLLOG_F(@"Activation Success: %@\n", success ? @"Yes" : @"No");
            NYPLLOG_F(@"Error: %@\n",error.localizedDescription);
            NYPLLOG_F(@"UserID: %@\n",userID);
            NYPLLOG_F(@"DeviceID: %@\n",deviceID);
            NYPLLOG(@"***DRM Auth/Activation Completion***");
            
            if (success) {
              // POST deviceID to adobeDevicesLink
              NSURL *deviceManager = [NSURL URLWithString: [[NYPLAccount sharedAccount] licensor][@"deviceManager"]];
              if (deviceManager != nil) {
                [NYPLDeviceManager postDevice:deviceID url:deviceManager];
              }
              
              [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [[NYPLAccount sharedAccount] setUserID:userID];
                [[NYPLAccount sharedAccount] setDeviceID:deviceID];
              }];
            }
            
            [self authorizationAttemptDidFinish:success error:error];
            
          }];
         
#else
         
         [self authorizationAttemptDidFinish:YES error:nil];
         
#endif

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
  NYPLAlertController *alert;
  NSString *title = NSLocalizedString(@"SettingsAccountViewControllerLoginFailed", nil);

  if (error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled)
  {
    NSString *message = NSLocalizedString(@"SettingsAccountViewControllerInvalidCredentials", nil);
    alert = [NYPLAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:nil]];
    NSInteger library = [[NYPLSettings sharedSettings] currentAccountIdentifier];
    if (library == 0 || library == 1) {
      [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Forgot Password?", nil)
                                                style:UIAlertActionStyleDefault
                                              handler:^(UIAlertAction * _Nonnull __unused action) {
                                                [self resetPasswordTapped];
                                              }]];
    }
  } else {
    alert = [NYPLAlertController alertWithTitle:@"SettingsAccountViewControllerLoginFailed" error:error];
  }

  [[NYPLRootTabBarController sharedController] safelyPresentViewController:alert
                                                                  animated:YES
                                                                completion:nil];

  [self updateLoginLogoutCellAppearance];
}

// GODO - Method and caller can be removed after 2.1.0 release.
- (void)resetPasswordTapped
{
  if ([[NYPLSettings sharedSettings] currentAccountIdentifier] == 0) {
    NSURL *url = [NSURL URLWithString:@"https://catalog.nypl.org/pinreset"];
    [[UIApplication sharedApplication] openURL:url];
  } else if ([[NYPLSettings sharedSettings] currentAccountIdentifier] == 1) {
    NSURL *url = [NSURL URLWithString:@"https://www.bklynlibrary.org/mybpl/prefs/pin"];
    [[UIApplication sharedApplication] openURL:url];
  }
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
    if((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ||
       (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact &&
        self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact)) {
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
      [[NYPLAccount sharedAccount] removeAll];
      [self accountDidChange];
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
