@import LocalAuthentication;
@import NYPLCardCreator;
@import CoreLocation;
@import MessageUI;

#import "NYPLSettingsAccountDetailViewController.h"

#import "NYPLAccount.h"
#import "NYPLBarcodeScanningViewController.h"
#import "NYPLBasicAuth.h"
#import "NYPLBookCoverRegistry.h"
#import "NYPLBookRegistry.h"
#import "NYPLCatalogNavigationController.h"
#import "NYPLLinearView.h"
#import "NYPLMyBooksDownloadCenter.h"

#import "NYPLSettingsEULAViewController.h"
#import "NYPLRootTabBarController.h"
#import "UIFont+NYPLSystemFontOverride.h"
#import "UIView+NYPLViewAdditions.h"
#import "SimplyE-Swift.h"
#import "NYPLXML.h"
#import "NYPLOPDS.h"
#import <PureLayout/PureLayout.h>
#import <ZXingObjC/ZXingObjC.h>

#if defined(FEATURE_DRM_CONNECTOR)
#import <ADEPT/ADEPT.h>
#endif

typedef NS_ENUM(NSInteger, CellKind) {
  CellKindAdvancedSettings,
  CellKindAgeCheck,
  CellKindBarcodeImage,
  CellKindBarcode,
  CellKindPIN,
  CellKindLogInSignOut,
  CellKindRegistration,
  CellKindSyncButton,
  CellKindAbout,
  CellKindPrivacyPolicy,
  CellKindContentLicense,
  CellReportIssue
};

@interface NYPLSettingsAccountDetailViewController () <NSURLSessionDelegate, UITextFieldDelegate, UIAlertViewDelegate>

@property (nonatomic) BOOL isLoggingInAfterSignUp;
@property (nonatomic) BOOL loggingInAfterBarcodeScan;
@property (nonatomic) UITextField *usernameTextField;
@property (nonatomic) UIImageView *barcodeImageView;
@property (nonatomic) UILabel *barcodeImageLabel;
@property (nonatomic) NSLayoutConstraint *barcodeHeightConstraint;
@property (nonatomic) NSLayoutConstraint *barcodeLabelSpaceConstraint;
@property (nonatomic) float userBrightnessSetting;

@property (nonatomic) NSMutableArray *tableData;
@property (nonatomic, copy) void (^completionHandler)(void);
@property (nonatomic) BOOL hiddenPIN;
@property (nonatomic) UITextField *PINTextField;
@property (nonatomic) NSURLSession *session;
@property (nonatomic) UIButton *PINShowHideButton;
@property (nonatomic) UIButton *barcodeScanButton;
@property (nonatomic) NSString *selectedAccountId;
@property (nonatomic) Account *selectedAccount;
@property (nonatomic) NYPLAccount *selectedNYPLAccount;

@property (nonatomic) BOOL loading;

@property (nonatomic) UITableViewCell *registrationCell;
@property (nonatomic) UITableViewCell *logInSignOutCell;
@property (nonatomic) UITableViewCell *ageCheckCell;

@property (nonatomic) UISwitch *syncSwitch;
@property (nonatomic) BOOL permissionCheckIsInProgress;

@end


@implementation NYPLSettingsAccountDetailViewController

NSInteger const linearViewTag = 1;
CGFloat const verticalMarginPadding = 2.0;
double const requestTimeoutInterval = 25.0;

#pragma mark NSObject

- (instancetype)initWithAccount:(NSString *)account
{
  self.selectedAccountId = account;
  self.selectedAccount = [[AccountsManager sharedInstance] account:self.selectedAccountId];
  self.selectedNYPLAccount = [NYPLAccount sharedAccount:self.selectedAccountId];
  return [self init];
}

- (instancetype)init
{
  self = [super initWithStyle:UITableViewStyleGrouped];
  if(!self) return nil;
  
  self.title = NSLocalizedString(@"Account", nil);

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
   selector:@selector(keyboardWillHide)
   name:UIKeyboardWillHideNotification
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
  
  self.view.backgroundColor = [NYPLConfiguration shared].backgroundColor;
  self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
  
  if (self.selectedAccount.details == nil) {
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleGray];
    activityIndicator.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
    [self.view addSubview:activityIndicator];
    [activityIndicator startAnimating];
    self.loading = true;
    [self.selectedAccount loadAuthenticationDocumentWithPreferringCache:NO completion:^(BOOL success) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [activityIndicator removeFromSuperview];
        if (success) {
          self.loading = false;
          [self setupViews];
          
          self.hiddenPIN = YES;
          [self accountDidChange];
          [self.tableView reloadData];
          [self updateShowHidePINState];
        } else {
          [self displayErrorMessage:NSLocalizedString(@"CheckConnection", nil)];
        }
      });
    }];
  } else {
    [self setupViews];
  }
}

- (void)displayErrorMessage:(NSString *)errorMessage {
  UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
  label.text = errorMessage;
  [label sizeToFit];
  label.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
  [self.view addSubview:label];
}

- (void)setupViews {
  self.usernameTextField = [[UITextField alloc] initWithFrame:CGRectZero];
  self.usernameTextField.delegate = self;
  self.usernameTextField.placeholder = NSLocalizedString(@"BarcodeOrUsername", nil);

  switch (self.selectedAccount.details.patronIDKeyboard) {
    case LoginKeyboardStandard:
    case LoginKeyboardNone:
      self.usernameTextField.keyboardType = UIKeyboardTypeASCIICapable;
      break;
    case LoginKeyboardEmail:
      self.usernameTextField.keyboardType = UIKeyboardTypeEmailAddress;
      break;
    case LoginKeyboardNumeric:
      self.usernameTextField.keyboardType = UIKeyboardTypeNumberPad;
      break;
  }

  self.usernameTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
  self.usernameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
  [self.usernameTextField
   addTarget:self
   action:@selector(textFieldsDidChange)
   forControlEvents:UIControlEventEditingChanged];

  self.barcodeScanButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.barcodeScanButton setImage:[UIImage imageNamed:@"CameraIcon"] forState:UIControlStateNormal];
  [self.barcodeScanButton addTarget:self action:@selector(scanLibraryCard)
                   forControlEvents:UIControlEventTouchUpInside];
  
  self.PINTextField = [[UITextField alloc] initWithFrame:CGRectZero];
  self.PINTextField.placeholder = NSLocalizedString(@"PIN", nil);

  switch (self.selectedAccount.details.pinKeyboard) {
    case LoginKeyboardStandard:
    case LoginKeyboardNone:
      self.PINTextField.keyboardType = UIKeyboardTypeASCIICapable;
      break;
    case LoginKeyboardEmail:
      self.PINTextField.keyboardType = UIKeyboardTypeEmailAddress;
      break;
    case LoginKeyboardNumeric:
      self.PINTextField.keyboardType = UIKeyboardTypeNumberPad;
      break;
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

  [self setupTableData];
  
  self.syncSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
  [self checkSyncPermissionForCurrentPatron];
}

- (void)setupTableData
{
  NSMutableArray *section0;
  if (self.selectedAccount.details.needsAgeCheck) {
    section0 = @[@(CellKindAgeCheck)].mutableCopy;
  } else if (!self.selectedAccount.details.needsAuth) {
    section0 = [NSMutableArray new];
  } else if (self.selectedAccount.details.pinKeyboard != LoginKeyboardNone) {
    section0 = @[@(CellKindBarcode),
                 @(CellKindPIN),
                 @(CellKindLogInSignOut)].mutableCopy;
  } else {
    //Server expects a blank string. Passes local textfield validation.
    self.PINTextField.text = @"";
    section0 = @[@(CellKindBarcode),
                 @(CellKindLogInSignOut)].mutableCopy;
  }
  
  NSMutableArray *sectionRegister = @[@(CellKindRegistration)].mutableCopy;

  if ([self librarySupportsBarcodeDisplay]) {
    [section0 insertObject:@(CellKindBarcodeImage) atIndex: 0];
  }
  NSMutableArray *section2 = [[NSMutableArray alloc] init];
  if ([self.selectedAccount.details getLicenseURL:URLTypePrivacyPolicy]) {
    [section2 addObject:@(CellKindPrivacyPolicy)];
  }
  if ([self.selectedAccount.details getLicenseURL:URLTypeContentLicenses]) {
    [section2 addObject:@(CellKindContentLicense)];
  }
  NSMutableArray *section1 = [[NSMutableArray alloc] init];
  if ([self syncButtonShouldBeVisible]) {
    [section1 addObject:@(CellKindSyncButton)];
    [section2 addObject:@(CellKindAdvancedSettings)];
  }
  
  if ([self registrationIsPossible]) {
    self.tableData = @[section0, sectionRegister, section1].mutableCopy;
  }
  else{
    self.tableData = @[section0, section1].mutableCopy;
  }
  
  NSMutableArray *reportIssue = [[NSMutableArray alloc] init];
  if (self.selectedAccount.supportEmail != nil)
  {
    [reportIssue addObject:@(CellReportIssue)];
    [self.tableData addObject:reportIssue];
  }
  [self.tableData addObject:section2];

  
  NSMutableArray *newArray = [[NSMutableArray alloc] init];
  for (NSMutableArray *section in self.tableData) {
    if ([section count] != 0) { [newArray addObject:section]; }
  }
  self.tableData = newArray;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  // The new credentials are not yet saved after signup or after scanning. As such,
  // reloading the table would lose the values in the barcode and PIN fields.
  if (self.isLoggingInAfterSignUp || self.loggingInAfterBarcodeScan) {
    return;
  } else {
    self.hiddenPIN = YES;
    [self accountDidChange];
    [self.tableView reloadData];
    [self updateShowHidePINState];
  }
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  if (self.userBrightnessSetting && [[UIScreen mainScreen] brightness] != self.userBrightnessSetting) {
    [[UIScreen mainScreen] setBrightness:self.userBrightnessSetting];
  }
}

- (BOOL)librarySupportsBarcodeDisplay
{
  // For now, only supports libraries granted access in Accounts.json,
  // is signed in, and has an authorization ID returned from the loans feed.
  return ((self.selectedNYPLAccount.hasBarcodeAndPIN) &&
          (self.selectedNYPLAccount.authorizationIdentifier) &&
          (self.selectedAccount.details.supportsBarcodeDisplay));
}

- (void)scanLibraryCard
{
  [NYPLBarcode presentScannerWithCompletion:^(NSString * _Nullable resultString) {
    if (resultString) {
      self.usernameTextField.text = resultString;
      [self.PINTextField becomeFirstResponder];
      self.loggingInAfterBarcodeScan = YES;
    }
  }];
}

#pragma mark - Account SignIn/SignOut

- (void)logIn
{
  assert(self.usernameTextField.text.length > 0);
  assert(self.PINTextField.text.length > 0 || [self.PINTextField.text isEqualToString:@""]);
  
  [self.usernameTextField resignFirstResponder];
  [self.PINTextField resignFirstResponder];
  
  [self setActivityTitleWithText:NSLocalizedString(@"Verifying", nil)];
  
  [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
  
  [self validateCredentials];
}

- (void)logOut
{
  
#if defined(FEATURE_DRM_CONNECTOR)
  
  if([NYPLADEPT sharedInstance].workflowsInProgress ||
     [NYPLBookRegistry sharedRegistry].syncing == YES) {
    [self presentViewController:[NYPLAlertUtils
                                 alertWithTitle:@"SettingsAccountViewControllerCannotLogOutTitle"
                                 message:@"SettingsAccountViewControllerCannotLogOutMessage"]
                       animated:YES
                     completion:nil];
    return;
  }
  
  [self setActivityTitleWithText:NSLocalizedString(@"SigningOut", nil)];
  [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
  
  
  // Get a fresh licensor token before attempting to deauthorize
  NSMutableURLRequest *const request =
  [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[[self.selectedAccount details] userProfileUrl]]];
  
  request.timeoutInterval = requestTimeoutInterval;
  
  NSURLSessionDataTask *const task =
  [self.session
   dataTaskWithRequest:request
   completionHandler:^(NSData *data,
                       NSURLResponse *const response,
                       __unused NSError *const error) {
     
     NSInteger statusCode = ((NSHTTPURLResponse *) response).statusCode;
     if (statusCode == 200) {
       NSError *pDocError = nil;
       UserProfileDocument *pDoc = [UserProfileDocument fromData:data error:&pDocError];
       if (!pDoc) {
         [NYPLBugsnagLogs reportUserProfileDocumentErrorWithError:pDocError];
         [self showLogoutAlertWithError:pDocError responseCode:statusCode];
         [self removeActivityTitle];
         [[UIApplication sharedApplication] endIgnoringInteractionEvents];
       } else {
         if (pDoc.drm.count > 0 && pDoc.drm[0].vendor && pDoc.drm[0].clientToken) {
           [self.selectedNYPLAccount setLicensor:[pDoc.drm[0] licensor]];
           NYPLLOG_F(@"\nLicensor Token Updated: %@\nFor account: %@", pDoc.drm[0].clientToken, self.selectedNYPLAccount.userID);
         } else {
           NYPLLOG_F(@"\nLicensor Token Invalid: %@", [pDoc toJson])
         }
         [self deauthorizeDevice];
       }
     } else {
       [self showLogoutAlertWithError:error responseCode:statusCode];
       [self removeActivityTitle];
       [[UIApplication sharedApplication] endIgnoringInteractionEvents];
     }
   }];

  [task resume];
  
#else

  if([NYPLBookRegistry sharedRegistry].syncing == YES) {
    [self presentViewController:[NYPLAlertController
                                 alertWithTitle:@"SettingsAccountViewControllerCannotLogOutTitle"
                                 message:@"SettingsAccountViewControllerCannotLogOutMessage"]
                       animated:YES
                     completion:nil];
  } else {
    [[NYPLMyBooksDownloadCenter sharedDownloadCenter] reset:self.selectedAccountType];
    [[NYPLBookRegistry sharedRegistry] reset:self.selectedAccountType];
    [[NYPLAccount sharedAccount:self.selectedAccountType] removeAll];
    [self setupTableData];
    [self.tableView reloadData];
    [self removeActivityTitle];
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
  }

#endif
  
}

- (void)deauthorizeDevice
{

#if defined(FEATURE_DRM_CONNECTOR)

  void (^afterDeauthorization)(void) = ^() {
    [self removeActivityTitle];
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    
    [[NYPLMyBooksDownloadCenter sharedDownloadCenter] reset:self.selectedAccountId];
    [[NYPLBookRegistry sharedRegistry] reset:self.selectedAccountId];
    
    [self.selectedNYPLAccount removeAll];
    [self setupTableData];
    [self.tableView reloadData];
  };

  NSDictionary *licensor = [self.selectedNYPLAccount licensor];
  if (!licensor) {
    NYPLLOG(@"No Licensor available to deauthorize device. Signing out NYPLAccount creds anyway.");
    [NYPLBugsnagLogs bugsnagLogInvalidLicensorWithAccountId:self.selectedAccountId];
    afterDeauthorization();
    return;
  }

  NSMutableArray *licensorItems = [[licensor[@"clientToken"] stringByReplacingOccurrencesOfString:@"\n" withString:@""] componentsSeparatedByString:@"|"].mutableCopy;
  NSString *tokenPassword = [licensorItems lastObject];
  [licensorItems removeLastObject];
  NSString *tokenUsername = [licensorItems componentsJoinedByString:@"|"];
  
  NYPLLOG(@"***DRM Deactivation Attempt***");
  NYPLLOG_F(@"\nLicensor: %@\n",licensor);
  NYPLLOG_F(@"Token Username: %@\n",tokenUsername);
  NYPLLOG_F(@"Token Password: %@\n",tokenPassword);
  NYPLLOG_F(@"UserID: %@\n",[self.selectedNYPLAccount userID]);
  NYPLLOG_F(@"DeviceID: %@\n",[self.selectedNYPLAccount deviceID]);
  
  [[NYPLADEPT sharedInstance]
   deauthorizeWithUsername:tokenUsername
   password:tokenPassword
   userID:[self.selectedNYPLAccount userID]
   deviceID:[self.selectedNYPLAccount deviceID]
   completion:^(BOOL success, __unused NSError *error) {
     
     if(!success) {
       // Even though we failed, let the user continue to log out.
       // The most likely reason is a user changing their PIN.
       [NYPLBugsnagLogs deauthorizationError];
     }
     else {
       NYPLLOG(@"***Successful DRM Deactivation***");
     }

     afterDeauthorization();
   }];
  
#endif

}

- (void)validateCredentials
{
  NSMutableURLRequest *const request =
  [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[[self.selectedAccount details] userProfileUrl]]];

  request.timeoutInterval = requestTimeoutInterval;

  NSURLSessionDataTask *const task =
  [self.session
   dataTaskWithRequest:request
   completionHandler:^(__unused NSData *data,
                       NSURLResponse *const response,
                       NSError *const error) {
      NSInteger const statusCode = ((NSHTTPURLResponse *) response).statusCode;
     
      if (statusCode == 200) {
#if defined(FEATURE_DRM_CONNECTOR)
        NSError *pDocError = nil;
        UserProfileDocument *pDoc = [UserProfileDocument fromData:data error:&pDocError];
        if (!pDoc) {
          [NYPLBugsnagLogs reportUserProfileDocumentErrorWithError:pDocError];
          [self authorizationAttemptDidFinish:NO error:nil];
          return;
        } else {
          if (pDoc.authorizationIdentifier) {
           [[NYPLAccount sharedAccount:self.selectedAccountId] setAuthorizationIdentifier:pDoc.authorizationIdentifier];
          } else {
           NYPLLOG(@"Authorization ID (Barcode String) was nil.");
          }
          if (pDoc.drm.count > 0 && pDoc.drm[0].vendor && pDoc.drm[0].clientToken) {
           [self.selectedNYPLAccount setLicensor:[pDoc.drm[0] licensor]];
          } else {
           NYPLLOG(@"Login Failed: No Licensor Token received or parsed from user profile document");
           [self authorizationAttemptDidFinish:NO error:nil];
           return;
          }

          NSMutableArray *licensorItems = [[pDoc.drm[0].clientToken stringByReplacingOccurrencesOfString:@"\n" withString:@""] componentsSeparatedByString:@"|"].mutableCopy;
          NSString *tokenPassword = [licensorItems lastObject];
          [licensorItems removeLastObject];
          NSString *tokenUsername = [licensorItems componentsJoinedByString:@"|"];

          NYPLLOG(@"***DRM Auth/Activation Attempt***");
          NYPLLOG_F(@"\nLicensor: %@\n",[pDoc.drm[0] licensor]);
          NYPLLOG_F(@"Token Username: %@\n",tokenUsername);
          NYPLLOG_F(@"Token Password: %@\n",tokenPassword);

          [[NYPLADEPT sharedInstance]
           authorizeWithVendorID:[self.selectedNYPLAccount licensor][@"vendor"]
           username:tokenUsername
           password:tokenPassword
           completion:^(BOOL success, NSError *error, NSString *deviceID, NSString *userID) {
            NYPLLOG_F(@"Activation Success: %@\n", success ? @"Yes" : @"No");
            NYPLLOG_F(@"Error: %@\n",error.localizedDescription);
            NYPLLOG_F(@"UserID: %@\n",userID);
            NYPLLOG_F(@"DeviceID: %@\n",deviceID);
            NYPLLOG(@"***DRM Auth/Activation Completion***");
            
            if (success) {
              [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self.selectedNYPLAccount setUserID:userID];
                [self.selectedNYPLAccount setDeviceID:deviceID];
              }];
            }
            
            [self authorizationAttemptDidFinish:success error:error];
          }];
        }
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
     } else {
       [self showLoginAlertWithError:error];
     }

     return;
   }];
  
  [task resume];
}

- (void)showLoginAlertWithError:(NSError *)error
{
  [[NYPLRootTabBarController sharedController] safelyPresentViewController:
   [NYPLAlertUtils alertWithTitle:@"SettingsAccountViewControllerLoginFailed" error:error]
                                                                  animated:YES
                                                                completion:nil];
  [self removeActivityTitle];
  [NYPLBugsnagLogs loginAlertErrorWithError:error code:error.code libraryName:self.selectedAccount.name];
}

- (void)showLogoutAlertWithError:(NSError *)error responseCode:(NSInteger)code
{
  NSString *title; NSString *message;
  if (code == 401) {
    title = @"Unexpected Credentials";
    message = @"Your username or password may have changed since the last time you logged in.\n\nIf you believe this is an error, please contact your library.";
    [self deauthorizeDevice];
  } else if (error) {
    title = @"SettingsAccountViewControllerLogoutFailed";
    message = error.localizedDescription;
  } else {
    title = @"SettingsAccountViewControllerLogoutFailed";
    message = NSLocalizedString(@"An unknown error occurred while trying to sign out.", nil);
  }
  [self presentViewController:[NYPLAlertUtils alertWithTitle:title message:message]
                     animated:YES
                   completion:nil];
}

- (void)authorizationAttemptDidFinish:(BOOL)success error:(NSError *)error
{
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [self removeActivityTitle];
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    
    if (success) {
      [self.selectedNYPLAccount setBarcode:self.usernameTextField.text PIN:self.PINTextField.text];

      if ([self.selectedAccountId isEqualToString:[AccountsManager shared].currentAccount.uuid]) {
        void (^handler)(void) = self.completionHandler;
        self.completionHandler = nil;
        if(handler) handler();
        [[NYPLBookRegistry sharedRegistry] syncWithCompletionHandler:^(BOOL __unused success) {
          if (success) {
            [[NYPLBookRegistry sharedRegistry] save];
          }
        }];
      }
    } else {
      [[NSNotificationCenter defaultCenter] postNotificationName:NSNotification.NYPLSyncEnded object:nil];
      [self showLoginAlertWithError:error];
    }
  }];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(__attribute__((unused)) UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *const)indexPath
{
  NSArray *sectionArray = (NSArray *)self.tableData[indexPath.section];
  CellKind cellKind = (CellKind)[sectionArray[indexPath.row] intValue];
  
  switch(cellKind) {
    case CellKindAgeCheck: {
      UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
      if (self.selectedAccount.details.userAboveAgeLimit == YES) {
        [self confirmAgeChange:^(BOOL under13) {
          if (under13) {
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CheckboxOff"]];
            self.selectedAccount.details.userAboveAgeLimit = NO;
            //Delete Books in My Books
            [[NYPLMyBooksDownloadCenter sharedDownloadCenter] reset:self.selectedAccountId];
            [[NYPLBookRegistry sharedRegistry] reset:self.selectedAccountId];
            NYPLCatalogNavigationController *catalog = (NYPLCatalogNavigationController*)[NYPLRootTabBarController sharedController].viewControllers[0];
            [catalog popToRootViewControllerAnimated:NO];
            [catalog updateFeedAndRegistryOnAccountChange];
          }
        }];
      } else {
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CheckboxOn"]];
        self.selectedAccount.details.userAboveAgeLimit = YES;
        NYPLCatalogNavigationController *catalog = (NYPLCatalogNavigationController*)[NYPLRootTabBarController sharedController].viewControllers[0];
        [catalog popToRootViewControllerAnimated:NO];
        [catalog updateFeedAndRegistryOnAccountChange];
      }
      break;
    }
    case CellKindBarcode:
      [self.usernameTextField becomeFirstResponder];
      break;
    case CellKindPIN:
      [self.PINTextField becomeFirstResponder];
      break;
    case CellKindLogInSignOut: {
      [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
      NSString *logoutString;
      if([self.selectedNYPLAccount hasBarcodeAndPIN]) {
        if ([self syncButtonShouldBeVisible] && !self.syncSwitch.on) {
          logoutString = NSLocalizedString(@"SettingsAccountViewControllerLogoutMessageSync", nil);
        } else {
          logoutString = NSLocalizedString(@"SettingsAccountViewControllerLogoutMessageDefault", nil);
        }
        UIAlertController *const alertController =
        (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad &&
         (self.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassCompact))
        ? [UIAlertController alertControllerWithTitle:NSLocalizedString(@"SignOut", nil)
                                              message:logoutString
                                       preferredStyle:UIAlertControllerStyleAlert]
        : [UIAlertController alertControllerWithTitle:logoutString
                                              message:nil
                                       preferredStyle:UIAlertControllerStyleActionSheet];
        alertController.popoverPresentationController.sourceRect = self.view.bounds;
        alertController.popoverPresentationController.sourceView = self.view;
        [alertController addAction:[UIAlertAction
                                    actionWithTitle:NSLocalizedString(@"SignOut", nil)
                                    style:UIAlertActionStyleDestructive
                                    handler:^(__attribute__((unused)) UIAlertAction *action) {
                                      [self logOut];
                                    }]];
        [alertController addAction:[UIAlertAction
                                    actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                    style:UIAlertActionStyleCancel
                                    handler:nil]];
        [self presentViewController:alertController animated:YES completion:^{
          alertController.view.tintColor = [NYPLConfiguration shared].mainColor;
        }];
      } else {
        [self logIn];
      }
      break;
    }
    case CellKindRegistration: {
      [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
      
      if (self.selectedAccount.details.supportsCardCreator) {

      __weak NYPLSettingsAccountDetailViewController *const weakSelf = self;
      CardCreatorConfiguration *const configuration =
      [[CardCreatorConfiguration alloc]
       initWithEndpointURL:[APIKeys cardCreatorEndpointURL]
       endpointVersion:[APIKeys cardCreatorVersion]
       endpointUsername:[APIKeys cardCreatorUsername]
       endpointPassword:[APIKeys cardCreatorPassword]
       requestTimeoutInterval:requestTimeoutInterval
       completionHandler:^(NSString *const username, NSString *const PIN, BOOL const userInitiated) {
         if (userInitiated) {
           // Dismiss CardCreator when user finishes Credential Review
           [weakSelf dismissViewControllerAnimated:YES completion:nil];
         } else {
           weakSelf.usernameTextField.text = username;
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
        
        RemoteHTMLViewController *webViewController = [[RemoteHTMLViewController alloc] initWithURL:[[NSURL alloc] initWithString:self.selectedAccount.details.cardCreatorUrl] title:@"eCard" failureMessage:NSLocalizedString(@"SettingsConnectionFailureMessage", nil)];
        
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
    case CellKindSyncButton: {
      break;
    }
    case CellKindAdvancedSettings: {
      NYPLSettingsAdvancedViewController *vc = [[NYPLSettingsAdvancedViewController alloc] initWithAccount:self.selectedAccountId];
      [self.navigationController pushViewController:vc animated:YES];
      break;
    }
    case CellKindBarcodeImage: {
      [self.tableView beginUpdates];
      // Collapse barcode by adjusting certain constraints
      if (self.barcodeHeightConstraint.constant > 0) {
        self.barcodeHeightConstraint.constant = 0.0;
        self.barcodeLabelSpaceConstraint.constant = 0.0;
        self.barcodeImageLabel.text = NSLocalizedString(@"Show Barcode", nil);
        [[UIScreen mainScreen] setBrightness:self.userBrightnessSetting];
      } else {
        self.barcodeHeightConstraint.constant = 100.0;
        self.barcodeLabelSpaceConstraint.constant = -12.0;
        self.barcodeImageLabel.text = NSLocalizedString(@"Hide Barcode", nil);
        self.userBrightnessSetting = [[UIScreen mainScreen] brightness];
        [[UIScreen mainScreen] setBrightness:1.0];
      }
      [self.tableView endUpdates];
      break;
    }
    case CellReportIssue: {
      [[ProblemReportEmail sharedInstance]
       beginComposingTo:self.selectedAccount.supportEmail
       presentingViewController:self
       book:nil];
      [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
      break;
    }
    case CellKindAbout: {
      RemoteHTMLViewController *vc = [[RemoteHTMLViewController alloc]
                                      initWithURL:[self.selectedAccount.details getLicenseURL:URLTypeAcknowledgements]
                                      title:NSLocalizedString(@"About", nil)
                                      failureMessage:NSLocalizedString(@"SettingsConnectionFailureMessage", nil)];
      [self.navigationController pushViewController:vc animated:YES];
      break;
    }
    case CellKindPrivacyPolicy: {
      RemoteHTMLViewController *vc = [[RemoteHTMLViewController alloc]
                                      initWithURL:[self.selectedAccount.details getLicenseURL:URLTypePrivacyPolicy]
                                      title:NSLocalizedString(@"PrivacyPolicy", nil)
                                      failureMessage:NSLocalizedString(@"SettingsConnectionFailureMessage", nil)];
      [self.navigationController pushViewController:vc animated:YES];
      break;
    }
    case CellKindContentLicense: {
      RemoteHTMLViewController *vc = [[RemoteHTMLViewController alloc]
                                      initWithURL:[self.selectedAccount.details getLicenseURL:URLTypeContentLicenses]
                                      title:NSLocalizedString(@"ContentLicenses", nil)
                                      failureMessage:NSLocalizedString(@"SettingsConnectionFailureMessage", nil)];
      [self.navigationController pushViewController:vc animated:YES];
      break;
    }
  }
}

- (void)showDetailVC:(UIViewController *)vc fromIndexPath:(NSIndexPath *)indexPath
{
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad &&
     self.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassCompact) {
    [self.splitViewController showDetailViewController:[[UINavigationController alloc]
                                                        initWithRootViewController:vc]
                                                sender:self];
  } else {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.splitViewController showDetailViewController:vc sender:self];
  }
}

- (void)didSelectCancelForSignUp
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(__attribute__((unused)) UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *const)indexPath
{
  NSArray *sectionArray = (NSArray *)self.tableData[indexPath.section];
  CellKind cellKind = (CellKind)[sectionArray[indexPath.row] intValue];

  switch(cellKind) {
    case CellKindBarcode: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      {
        self.usernameTextField.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
        [cell.contentView addSubview:self.usernameTextField];
        self.usernameTextField.preservesSuperviewLayoutMargins = YES;
        [self.usernameTextField autoPinEdgeToSuperviewMargin:ALEdgeRight];
        [self.usernameTextField autoPinEdgeToSuperviewMargin:ALEdgeLeft];
        [self.usernameTextField autoConstrainAttribute:ALAttributeTop toAttribute:ALAttributeMarginTop
                                               ofView:[self.usernameTextField superview]
                                           withOffset:verticalMarginPadding];
        [self.usernameTextField autoConstrainAttribute:ALAttributeBottom toAttribute:ALAttributeMarginBottom
                                               ofView:[self.usernameTextField superview]
                                           withOffset:-verticalMarginPadding];

        if (self.selectedAccount.details.supportsBarcodeScanner) {
          [cell.contentView addSubview:self.barcodeScanButton];
          CGFloat rightMargin = cell.layoutMargins.right;
          self.barcodeScanButton.contentEdgeInsets = UIEdgeInsetsMake(0, rightMargin * 2, 0, rightMargin);
          [self.barcodeScanButton autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeLeading];
          if (!self.usernameTextField.enabled) {
            self.barcodeScanButton.hidden = YES;
          }
        }
      }
      return cell;
    }
    case CellKindBarcodeImage:{
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;


      if (![self librarySupportsBarcodeDisplay]) {
        NYPLLOG(@"A nonvalid library was attempting to create a barcode image.");
      } else {
        NYPLBarcode *barcode = [[NYPLBarcode alloc] initWithLibrary:self.selectedAccount.name];
        UIImage *barcodeImage = [barcode imageFromString:self.selectedNYPLAccount.authorizationIdentifier
                                          superviewWidth:self.tableView.bounds.size.width
                                                    type:NYPLBarcodeTypeCodabar];

        if (barcodeImage) {
          self.barcodeImageView = [[UIImageView alloc] initWithImage:barcodeImage];
          self.barcodeImageLabel = [[UILabel alloc] init];
          self.barcodeImageLabel.text = NSLocalizedString(@"Show Barcode", nil);
          self.barcodeImageLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
          self.barcodeImageLabel.textColor = [NYPLConfiguration shared].mainColor;

          [cell.contentView addSubview:self.barcodeImageView];
          [cell.contentView addSubview:self.barcodeImageLabel];
          [self.barcodeImageView autoAlignAxisToSuperviewAxis:ALAxisVertical];
          [self.barcodeImageView autoSetDimension:ALDimensionWidth toSize:self.tableView.bounds.size.width];
          [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultHigh forConstraints:^{
            // Hidden to start
            self.barcodeHeightConstraint = [self.barcodeImageView autoSetDimension:ALDimensionHeight toSize:0];
            self.barcodeLabelSpaceConstraint = [self.barcodeImageView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.barcodeImageLabel withOffset:0];
          }];
          [self.barcodeImageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:12.0];
          [self.barcodeImageLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
          [self.barcodeImageLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:10.0];
        }
      }
      return cell;
    }
    case CellKindPIN: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      {
        self.PINTextField.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
        [cell.contentView addSubview:self.PINTextField];
        self.PINTextField.preservesSuperviewLayoutMargins = YES;
        [self.PINTextField autoPinEdgeToSuperviewMargin:ALEdgeRight];
        [self.PINTextField autoPinEdgeToSuperviewMargin:ALEdgeLeft];
        [self.PINTextField autoConstrainAttribute:ALAttributeTop toAttribute:ALAttributeMarginTop
                                           ofView:[self.PINTextField superview]
                                       withOffset:2.0];
        [self.PINTextField autoConstrainAttribute:ALAttributeBottom toAttribute:ALAttributeMarginBottom
                                           ofView:[self.PINTextField superview]
                                       withOffset:-2.0];
      }
      return cell;
    }
    case CellKindLogInSignOut: {
      if(!self.logInSignOutCell) {
        self.logInSignOutCell = [[UITableViewCell alloc]
                                initWithStyle:UITableViewCellStyleDefault
                                reuseIdentifier:nil];
        self.logInSignOutCell.textLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
      }
      [self updateLoginLogoutCellAppearance];
      return self.logInSignOutCell;
    }
    case CellKindRegistration: {
      return [self createRegistrationCell];
    }
    case CellKindAgeCheck: {
      self.ageCheckCell = [[UITableViewCell alloc]
                           initWithStyle:UITableViewCellStyleDefault
                           reuseIdentifier:nil];
      if (self.selectedAccount.details.userAboveAgeLimit) {
        self.ageCheckCell.accessoryView = [[UIImageView alloc] initWithImage:
                                           [UIImage imageNamed:@"CheckboxOn"]];
      } else {
        self.ageCheckCell.accessoryView = [[UIImageView alloc] initWithImage:
                                           [UIImage imageNamed:@"CheckboxOff"]];
      }
      self.ageCheckCell.selectionStyle = UITableViewCellSelectionStyleNone;
      self.ageCheckCell.textLabel.font = [UIFont systemFontOfSize:13];
      self.ageCheckCell.textLabel.text = NSLocalizedString(@"SettingsAccountAgeCheckbox",
                                                           @"Statement that confirms if a user meets the age requirement to download books");
      self.ageCheckCell.textLabel.numberOfLines = 2;
      return self.ageCheckCell;
    }
    case CellKindSyncButton: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      self.syncSwitch.on = self.selectedAccount.details.syncPermissionGranted;
      cell.accessoryView = self.syncSwitch;
      [self.syncSwitch addTarget:self action:@selector(syncSwitchChanged:) forControlEvents:UIControlEventValueChanged];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      cell.textLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
      cell.textLabel.text = NSLocalizedString(@"SettingsBookmarkSyncTitle",
                                              @"Title for switch to turn on or off syncing.");
      return cell;
    }
    case CellReportIssue: {
      UITableViewCell *cell = [[UITableViewCell alloc]
                               initWithStyle:UITableViewCellStyleDefault
                               reuseIdentifier:nil];
      cell.textLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
      cell.textLabel.text = NSLocalizedString(@"Report an Issue", nil);
      return cell;
    }
    case CellKindAbout: {
      UITableViewCell *cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      cell.textLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
      cell.textLabel.text = [NSString stringWithFormat:@"About %@",self.selectedAccount.name];
      cell.hidden = ([self.selectedAccount.details getLicenseURL:URLTypeAcknowledgements]) ? NO : YES;
      return cell;
    }
    case CellKindPrivacyPolicy: {
      UITableViewCell *cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      cell.textLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
      cell.textLabel.text = NSLocalizedString(@"PrivacyPolicy", nil);
      cell.hidden = ([self.selectedAccount.details getLicenseURL:URLTypePrivacyPolicy]) ? NO : YES;
      return cell;
    }
    case CellKindContentLicense: {
      UITableViewCell *cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      cell.textLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
      cell.textLabel.text = NSLocalizedString(@"ContentLicenses", nil);
      cell.hidden = ([self.selectedAccount.details getLicenseURL:URLTypeContentLicenses]) ? NO : YES;
      return cell;
    }
    case CellKindAdvancedSettings: {
      UITableViewCell *cell = [[UITableViewCell alloc]
                               initWithStyle:UITableViewCellStyleDefault
                               reuseIdentifier:nil];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      cell.textLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
      cell.textLabel.text = NSLocalizedString(@"Advanced", nil);
      return cell;
    }
    default: {
      return nil;
    }
  }
}

- (UITableViewCell *)createRegistrationCell
{
  UIView *containerView = [[UIView alloc] init];
  UILabel *regTitle = [[UILabel alloc] init];
  UILabel *regButton = [[UILabel alloc] init];

  regTitle.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
  regTitle.numberOfLines = 2;
  regTitle.text = NSLocalizedString(@"SettingsAccountRegistrationTitle", @"Title for registration. Asking the user if they already have a library card.");
  regButton.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
  regButton.text = NSLocalizedString(@"SignUp", nil);
  regButton.textColor = [NYPLConfiguration shared].mainColor;

  [containerView addSubview:regTitle];
  [containerView addSubview:regButton];
  [regTitle autoPinEdgeToSuperviewMargin:ALEdgeLeft];
  [regTitle autoConstrainAttribute:ALAttributeTop toAttribute:ALAttributeMarginTop ofView:[regTitle superview] withOffset:verticalMarginPadding];
  [regTitle autoConstrainAttribute:ALAttributeBottom toAttribute:ALAttributeMarginBottom ofView:[regTitle superview] withOffset:-verticalMarginPadding];
  [regButton autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:regTitle withOffset:8.0 relation:NSLayoutRelationGreaterThanOrEqual];
  [regButton autoPinEdgeToSuperviewMargin:ALEdgeRight];
  [regButton autoAlignAxisToSuperviewMarginAxis:ALAxisHorizontal];
  [regButton setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

  UITableViewCell *cell = [[UITableViewCell alloc] init];
  [cell.contentView addSubview:containerView];
  containerView.preservesSuperviewLayoutMargins = YES;
  [containerView autoPinEdgesToSuperviewEdges];
  return cell;
}

- (NSInteger)numberOfSectionsInTableView:(__attribute__((unused)) UITableView *)tableView
{
  return self.loading ? 0 : self.tableData.count;
}

- (NSInteger)tableView:(__attribute__((unused)) UITableView *)tableView
 numberOfRowsInSection:(NSInteger const)section
{
  if (section > (int)self.tableData.count - 1) {
    return 0;
  } else {
    return [(NSArray *)self.tableData[section] count];
  }
}

- (CGFloat)tableView:(__unused UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
  if (section == 0) {
    return UITableViewAutomaticDimension;
  } else {
    return 0;
  }
}
- (CGFloat)tableView:(__unused UITableView *)tableView heightForFooterInSection:(__unused NSInteger)section
{
  return UITableViewAutomaticDimension;
}
-(CGFloat)tableView:(__unused UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section
{
  if (section == 0) {
    return 80;
  } else {
    return 0;
  }
}
- (CGFloat)tableView:(__unused UITableView *)tableView estimatedHeightForFooterInSection:(__unused NSInteger)section
{
  return 44;
}

- (CGFloat)tableView:(__unused UITableView *)tableView estimatedHeightForRowAtIndexPath:(__unused NSIndexPath *)indexPath
{
  return 44;
}
-(CGFloat)tableView:(__unused UITableView *)tableView heightForRowAtIndexPath:(__unused NSIndexPath *)indexPath
{
  return UITableViewAutomaticDimension;
}

- (UIView *)tableView:(__unused UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
  if (section == 0) {
    UIView *containerView = [[UIView alloc] init];
    containerView.preservesSuperviewLayoutMargins = YES;
    UILabel *titleLabel = [[UILabel alloc] init];
    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.numberOfLines = 0;
    UIImageView *logoView = [[UIImageView alloc] initWithImage:self.selectedAccount.logo];
    logoView.contentMode = UIViewContentModeScaleAspectFit;
    
    titleLabel.text = self.selectedAccount.name;
    titleLabel.font = [UIFont systemFontOfSize:14];
    subtitleLabel.text = self.selectedAccount.subtitle;
    if (subtitleLabel.text == nil || [subtitleLabel.text isEqualToString:@""]) {
      subtitleLabel.text = @" "; // Make sure it takes up at least some space
    }
    subtitleLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:12];
    
    [containerView addSubview:titleLabel];
    [containerView addSubview:subtitleLabel];
    [containerView addSubview:logoView];
    
    [logoView autoSetDimensionsToSize:CGSizeMake(45, 45)];
    [logoView autoPinEdgeToSuperviewMargin:ALEdgeLeft];
    [logoView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:16];
    
    [titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:16];
    [titleLabel autoPinEdgeToSuperviewMargin:ALEdgeRight];
    [titleLabel autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:logoView withOffset:8];
    
    [subtitleLabel autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:titleLabel];
    [subtitleLabel autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:titleLabel];
    [subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:titleLabel withOffset:0];
    [subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:20];
    
    return containerView;
  } else {



    return nil;
  }
}

- (UIView *)tableView:(UITableView *)__unused tableView viewForFooterInSection:(NSInteger)section
{
  if ((section == 0 && [self.selectedAccount.details getLicenseURL:URLTypeEula]) ||
      (section == 1 && [self syncButtonShouldBeVisible])) {

    UIView *container = [[UIView alloc] init];
    container.preservesSuperviewLayoutMargins = YES;
    UILabel *footerLabel = [[UILabel alloc] init];
    footerLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleCaption1];
    footerLabel.textColor = [UIColor lightGrayColor];
    footerLabel.numberOfLines = 0;
    footerLabel.userInteractionEnabled = YES;

    NSMutableAttributedString *eulaString;
    if (section == 0) {
      [footerLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showEULA)]];

      NSDictionary *linkAttributes = @{ NSForegroundColorAttributeName :
                                          [UIColor colorWithRed:0.05 green:0.4 blue:0.65 alpha:1.0],
                                        NSUnderlineStyleAttributeName :
                                          @(NSUnderlineStyleSingle) };
      eulaString = [[NSMutableAttributedString alloc]
                    initWithString:NSLocalizedString(@"SigningInAgree", nil) attributes:linkAttributes];
    } else {

      footerLabel.textColor = [UIColor blackColor];
      eulaString = [[NSMutableAttributedString alloc]
                    initWithString:NSLocalizedString(@"SettingsAccountSyncFooterTitle",
                                                     @"Explain to the user they can save their bookmarks in the cloud across all their devices.")
                    attributes:nil];

    }
    footerLabel.attributedText = eulaString;

    [container addSubview:footerLabel];
    [footerLabel autoPinEdgeToSuperviewMargin:ALEdgeLeft];
    [footerLabel autoPinEdgeToSuperviewMargin:ALEdgeRight];
    [footerLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:8.0];
    [footerLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:16.0 relation:NSLayoutRelationGreaterThanOrEqual];

    return container;
  } else {
    return nil;
  }
}

- (BOOL)textFieldShouldBeginEditing:(__unused UITextField *)textField
{
  return ![self.selectedNYPLAccount hasBarcodeAndPIN];
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
                             self.usernameTextField.text,
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

  if(textField == self.usernameTextField &&
     self.selectedAccount.details.patronIDKeyboard != LoginKeyboardEmail) {
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
    
    NSCharacterSet *charSet = [NSCharacterSet decimalDigitCharacterSet];
    bool alphanumericPin = self.selectedAccount.details.pinKeyboard != LoginKeyboardNumeric;
    bool containsNonNumericChar = [string stringByTrimmingCharactersInSet:charSet].length > 0;
    bool abovePinCharLimit = [textField.text stringByReplacingCharactersInRange:range withString:string].length > self.selectedAccount.details.authPasscodeLength;
    
    // PIN's support numeric or alphanumeric.
    if (!alphanumericPin && containsNonNumericChar) {
      return NO;
    }
    // PIN's character limit. Zero is unlimited.
    if (self.selectedAccount.details.authPasscodeLength == 0) {
      return YES;
    } else if (abovePinCharLimit) {
      return NO;
    }
  }

  return YES;
}

- (void)textFieldsDidChange
{
  [self updateLoginLogoutCellAppearance];
}

- (void)keyboardWillHide
{
  self.registrationCell.textLabel.enabled = YES;
  self.registrationCell.detailTextLabel.enabled = YES;
  self.registrationCell.userInteractionEnabled = YES;
}

- (void)keyboardDidShow:(NSNotification *const)notification
{
  self.registrationCell.textLabel.enabled = NO;
  self.registrationCell.detailTextLabel.enabled = NO;
  self.registrationCell.userInteractionEnabled = NO;
  
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
    if(self.selectedNYPLAccount.hasBarcodeAndPIN) {
      [self checkSyncPermissionForCurrentPatron];
      self.usernameTextField.text = self.selectedNYPLAccount.barcode;
      self.usernameTextField.enabled = NO;
      self.usernameTextField.textColor = [UIColor grayColor];
      self.PINTextField.text = self.selectedNYPLAccount.PIN;
      self.PINTextField.textColor = [UIColor grayColor];
      self.barcodeScanButton.hidden = YES;
    } else {
      self.usernameTextField.text = nil;
      self.usernameTextField.enabled = YES;
      self.usernameTextField.textColor = [UIColor blackColor];
      self.PINTextField.text = nil;
      self.PINTextField.textColor = [UIColor blackColor];
      self.barcodeScanButton.hidden = NO;
    }
    
    [self setupTableData];
    [self.tableView reloadData];
    
    [self updateLoginLogoutCellAppearance];
  }];
}

- (void)updateLoginLogoutCellAppearance
{
  if([self.selectedNYPLAccount hasBarcodeAndPIN]) {
    self.logInSignOutCell.textLabel.text = NSLocalizedString(@"SignOut", nil);
    self.logInSignOutCell.textLabel.textAlignment = NSTextAlignmentCenter;
    self.logInSignOutCell.textLabel.textColor = [NYPLConfiguration shared].mainColor;
    self.logInSignOutCell.userInteractionEnabled = YES;
  } else {
    self.logInSignOutCell.textLabel.text = NSLocalizedString(@"LogIn", nil);
    self.logInSignOutCell.textLabel.textAlignment = NSTextAlignmentLeft;
    BOOL const barcodeHasText = [self.usernameTextField.text
                                 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length;
    BOOL const pinHasText = [self.PINTextField.text
                             stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length;
    BOOL const pinIsNotRequired = self.selectedAccount.details.pinKeyboard == LoginKeyboardNone;
    if((barcodeHasText && pinHasText) || (barcodeHasText && pinIsNotRequired)) {
      self.logInSignOutCell.userInteractionEnabled = YES;
      self.logInSignOutCell.textLabel.textColor = [NYPLConfiguration shared].mainColor;
    } else {
      self.logInSignOutCell.userInteractionEnabled = NO;
      self.logInSignOutCell.textLabel.textColor = [UIColor lightGrayColor];
    }
  }
}

- (void)setActivityTitleWithText:(NSString *)text
{
  UIActivityIndicatorView *const activityIndicatorView =
  [[UIActivityIndicatorView alloc]
   initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  
  [activityIndicatorView startAnimating];
  
  UILabel *const titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  titleLabel.text = text;
  titleLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
  [titleLabel sizeToFit];
  
  // This view is used to keep the title label centered as in Apple's Settings application.
  UIView *const rightPaddingView = [[UIView alloc] initWithFrame:activityIndicatorView.bounds];
  
  NYPLLinearView *const linearView = [[NYPLLinearView alloc] init];
  linearView.tag = linearViewTag;
  linearView.contentVerticalAlignment = NYPLLinearViewContentVerticalAlignmentMiddle;
  linearView.padding = 5.0;
  [linearView addSubview:activityIndicatorView];
  [linearView addSubview:titleLabel];
  [linearView addSubview:rightPaddingView];
  [linearView sizeToFit];
  [linearView autoSetDimensionsToSize:CGSizeMake(linearView.frame.size.width, linearView.frame.size.height)];
  
  self.logInSignOutCell.textLabel.text = nil;
  if (![self.logInSignOutCell.contentView viewWithTag:linearViewTag]) {
    [self.logInSignOutCell.contentView addSubview:linearView];
  }
  [linearView autoCenterInSuperview];
}

- (void)removeActivityTitle {
  UIView *view = [self.logInSignOutCell.contentView viewWithTag:linearViewTag];
  [view removeFromSuperview];
  [self updateLoginLogoutCellAppearance];
}

- (void)showEULA
{
  UIViewController *eulaViewController = [[NYPLSettingsEULAViewController alloc] initWithAccount:self.selectedAccount];
  UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:eulaViewController];
  [self.navigationController presentViewController:navVC animated:YES completion:nil];
}

- (void)confirmAgeChange:(void (^)(BOOL))completion
{
  UIAlertController *alertCont = [UIAlertController
                                    alertControllerWithTitle:NSLocalizedString(@"Age Verification", @"An alert title indicating the user needs to verify their age")
                                    message:NSLocalizedString(@"SettingsAccountViewControllerAgeCheckMessage",
                                                              @"An alert message warning the user they will lose their downloaded books if they continue.")
                                    preferredStyle:UIAlertControllerStyleAlert];
  
  [alertCont addAction: [UIAlertAction actionWithTitle:NSLocalizedString(@"Under 13", comment: @"A button title indicating an age range")
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * _Nonnull __unused action) {
                                                 if (completion) { completion(YES); }
                                               }]];
  
  [alertCont addAction: [UIAlertAction actionWithTitle:NSLocalizedString(@"13 or Older", comment: @"A button title indicating an age range")
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * _Nonnull __unused action) {
                                                 if (completion) { completion(NO); }
                                               }]];

  if ([self.selectedAccountId isEqualToString:[AccountsManager NYPLAccountUUIDs][2]]) {
    [NYPLAlertUtils presentFromViewControllerOrNilWithAlertController:alertCont viewController:nil animated:YES completion:nil];
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

- (BOOL)registrationIsPossible
{
  return ([NYPLConfiguration shared].cardCreationEnabled &&
          (self.selectedAccount.details.supportsCardCreator || self.selectedAccount.details.cardCreatorUrl) &&
          ![self.selectedNYPLAccount hasBarcodeAndPIN]);
}

- (void)syncSwitchChanged:(UISwitch*)sender
{
  // When switching on, attempt to enable on the server.
  // When switching off, just ignore the server's annotations.
  if (sender.on) {
    self.syncSwitch.enabled = NO;
    [NYPLAnnotations updateServerSyncSettingToEnabled:YES completion:^(BOOL success) {
      if (success) {
        self.selectedAccount.details.syncPermissionGranted = YES;
        self.syncSwitch.on = YES;
      } else {
        self.selectedAccount.details.syncPermissionGranted = NO;
        self.syncSwitch.on = NO;
      }
      self.syncSwitch.enabled = YES;
    }];
  } else {
    self.selectedAccount.details.syncPermissionGranted = NO;
    self.syncSwitch.on = NO;
  }
}

- (void)checkSyncPermissionForCurrentPatron
{
  if (self.permissionCheckIsInProgress || !self.selectedAccount.details.supportsSimplyESync) {
    NYPLLOG(@"Skipping sync setting check. Request already in progress or sync not supported.");
    return;
  }

  self.permissionCheckIsInProgress = YES;
  self.syncSwitch.enabled = NO;

  [NYPLAnnotations requestServerSyncStatusForAccount:self.selectedNYPLAccount completion:^(BOOL enableSync) {
    if (enableSync == YES) {
      self.selectedAccount.details.syncPermissionGranted = enableSync;
    }
    self.syncSwitch.on = enableSync;
    self.syncSwitch.enabled = YES;
    self.permissionCheckIsInProgress = NO;
  }];
}

- (BOOL)syncButtonShouldBeVisible
{
  // Only supported for now on current active library account
  return ((self.selectedAccount.details.supportsSimplyESync) &&
          ([self.selectedAccount.details getLicenseURL:URLTypeAnnotations] &&
           [self.selectedNYPLAccount hasBarcodeAndPIN]) &&
           ([self.selectedAccountId isEqualToString:[AccountsManager shared].currentAccount.uuid]));
}

- (void)didSelectCancel
{
  [self.navigationController.presentingViewController
   dismissViewControllerAnimated:YES
   completion:nil];
}

#pragma mark - View Controller Methods

- (void)willResignActive
{
  if(!self.PINTextField.secureTextEntry) {
    [self togglePINShowHideState];
  }
}

- (void)willEnterForeground
{
  // We update the state again in case the user enabled or disabled an authentication mechanism.
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [self updateShowHidePINState];
  }];
}

- (void)viewWillTransitionToSize:(__unused CGSize)size
       withTransitionCoordinator:(__unused id<UIViewControllerTransitionCoordinator>)coordinator
{
  [self.tableView reloadData];
}

@end
