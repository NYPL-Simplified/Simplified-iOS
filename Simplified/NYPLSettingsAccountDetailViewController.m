@import LocalAuthentication;
@import NYPLCardCreator;
@import CoreLocation;
@import MessageUI;

#import <PureLayout/PureLayout.h>
#import <ZXingObjC/ZXingObjC.h>

#import "NYPLBookCoverRegistry.h"
#import "NYPLBookRegistry.h"
#import "NYPLCatalogNavigationController.h"
#import "NYPLConfiguration.h"
#import "NYPLLinearView.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLOPDS.h"
#import "NYPLRootTabBarController.h"
#import "NYPLSettingsAccountDetailViewController.h"
#import "NYPLSettingsAccountURLSessionChallengeHandler.h"
#import "NYPLSettingsEULAViewController.h"
#import "NYPLXML.h"
#import "UIFont+NYPLSystemFontOverride.h"
#import "UIView+NYPLViewAdditions.h"
#import "SimplyE-Swift.h"

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
  CellKindJuvenile,
  CellKindSyncButton,
  CellKindAbout,
  CellKindPrivacyPolicy,
  CellKindContentLicense,
  CellReportIssue
};

@interface NYPLSettingsAccountDetailViewController () <NYPLUserAccountInputProvider, NYPLSettingsAccountUIDelegate, NYPLLogOutExecutor>

// State machine
@property (nonatomic) BOOL isLoggingInAfterSignUp;
@property (nonatomic) BOOL loggingInAfterBarcodeScan;
@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL hiddenPIN;

// UI
@property (nonatomic) UIImageView *barcodeImageView;
@property (nonatomic) UILabel *barcodeTextLabel;
@property (nonatomic) UILabel *barcodeImageLabel;
@property (nonatomic) NSLayoutConstraint *barcodeHeightConstraint;
@property (nonatomic) NSLayoutConstraint *barcodeTextHeightConstraint;
@property (nonatomic) NSLayoutConstraint *barcodeTextLabelSpaceConstraint;
@property (nonatomic) NSLayoutConstraint *barcodeLabelSpaceConstraint;
@property (nonatomic) float userBrightnessSetting;
@property (nonatomic) NSMutableArray *tableData;
@property (nonatomic) UIButton *PINShowHideButton;
@property (nonatomic) UIButton *barcodeScanButton;
@property (nonatomic) UITableViewCell *logInSignOutCell;
@property (nonatomic) UITableViewCell *ageCheckCell;
@property (nonatomic) UISwitch *syncSwitch;
@property (nonatomic) UIView *accountInfoHeaderView;
@property (nonatomic) UIView *accountInfoFooterView;
@property (nonatomic) UIView *syncFooterView;
@property (nonatomic) UIActivityIndicatorView *juvenileActivityView;

// account state
@property NYPLUserAccountFrontEndValidation *frontEndValidator;
@property (nonatomic) NYPLSignInBusinessLogic *businessLogic;
@property (nonatomic) NSString *authToken;
@property (nonatomic) NSDictionary *patron;
@property (nonatomic) NSArray *cookies;

// networking
@property (nonatomic) NSURLSession *session;
@property (nonatomic) NYPLSettingsAccountURLSessionChallengeHandler *urlSessionDelegate;

@end

static const NSInteger sLinearViewTag = 1;
static const CGFloat sVerticalMarginPadding = 2.0;

// table view sections indeces
static const NSInteger sSection0AccountInfo = 0;
static const NSInteger sSection1Sync = 1;

// Constraint constants
static const CGFloat sConstantZero = 0.0;
static const CGFloat sConstantSpacing = 12.0;

@implementation NYPLSettingsAccountDetailViewController

/*
 For NYPL, this field can accept any of the following:
 - a username
 - a 14-digit NYPL-issued barcode
 - a 16-digit NYC ID issued by the city of New York to its residents. Patrons
 can set up the NYC ID as a NYPL barcode even if they already have a NYPL card.
 All of these types of authentication can be used with the PIN to sign in.
 - Note: A patron can have multiple barcodes, because patrons may lose
their library card and get a new one with a different barcode.
Authenticating with any of those barcodes should work.
 */
@synthesize usernameTextField;

@synthesize PINTextField;

#pragma mark - Computed variables

- (NSString *)selectedAccountId
{
  return self.businessLogic.libraryAccountID;
}

- (nullable Account *)selectedAccount
{
  return self.businessLogic.libraryAccount;
}

- (NYPLUserAccount *)selectedUserAccount
{
  return self.businessLogic.userAccount;
}

#pragma mark - NSObject

// Overriding superclass's designated initializer
- (instancetype)initWithStyle:(__unused UITableViewStyle)style
{
  NSString *libraryID = [[AccountsManager shared] currentAccountId];
  NSAssert(libraryID, @"Tried to initialize NYPLSettingsAccountDetailViewController with the current library ID but that appears to be nil. A release build will continue with an empty library ID but this will likely produce unexpected behavior.");
  return [self initWithLibraryAccountID:libraryID ?: @""];
}

- (instancetype)initWithLibraryAccountID:(NSString *)libraryUUID
{
  self = [super initWithStyle:UITableViewStyleGrouped];
  if(!self) return nil;

  id<NYPLDRMAuthorizing> drmAuthorizer = nil;
#if defined(FEATURE_DRM_CONNECTOR)
  drmAuthorizer = [NYPLADEPT sharedInstance];
#endif

  self.businessLogic = [[NYPLSignInBusinessLogic alloc]
                        initWithLibraryAccountID:libraryUUID
                        bookRegistry:[NYPLBookRegistry sharedRegistry]
                        drmAuthorizer:drmAuthorizer];

  self.title = NSLocalizedString(@"Account", nil);

  self.frontEndValidator = [[NYPLUserAccountFrontEndValidation alloc]
                            initWithAccount:self.selectedAccount
                            businessLogic:self.businessLogic
                            inputProvider:self];

  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(accountDidChange)
   name:NSNotification.NYPLUserAccountDidChange
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

  _urlSessionDelegate = [[NYPLSettingsAccountURLSessionChallengeHandler alloc]
                         initWithUIDelegate:self];

  self.session = [NSURLSession
                  sessionWithConfiguration:configuration
                  delegate:_urlSessionDelegate
                  delegateQueue:[NSOperationQueue mainQueue]];

  return self;
}

- (void)dealloc
{
  [self.session finishTasksAndInvalidate];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIViewController + Views Preparation

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
  self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
  
  if (self.selectedAccount.details == nil) {
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleGray];
    activityIndicator.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
    [self.view addSubview:activityIndicator];
    [activityIndicator startAnimating];
    self.loading = true;
    [self.selectedAccount loadAuthenticationDocumentUsingSignedInStateProvider:self.businessLogic completion:^(BOOL success) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [activityIndicator removeFromSuperview];
        if (success) {
          self.loading = false;
          [self setupViews];
          
          self.hiddenPIN = YES;
          [self accountDidChange];
          [self updateShowHidePINState];
        } else {
          // ok not to log error, since it's done by
          // loadAuthenticationDocumentWithCompletion
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
  [self.view addSubview:label];
  [label centerInSuperviewWithOffset:self.tableView.contentOffset];
}

- (void)setupViews {
  self.usernameTextField = [[UITextField alloc] initWithFrame:CGRectZero];
  self.usernameTextField.delegate = self.frontEndValidator;
  self.usernameTextField.placeholder =
  self.businessLogic.selectedAuthentication.patronIDLabel ?: NSLocalizedString(@"BarcodeOrUsername", nil);

  switch (self.businessLogic.selectedAuthentication.patronIDKeyboard) {
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
  self.PINTextField.placeholder = self.businessLogic.selectedAuthentication.pinLabel ?: NSLocalizedString(@"PIN", nil);

  switch (self.businessLogic.selectedAuthentication.pinKeyboard) {
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
  self.PINTextField.delegate = self.frontEndValidator;
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

- (NSArray *) cellsForAuthMethod:(AccountDetailsAuthentication *)authenticationMethod {
  NSArray *authCells;

  if (authenticationMethod.isOauth) {
    // if authentication method is Oauth, just insert login/logout button, it will decide what to do by itself
    authCells = @[@(CellKindLogInSignOut)];
  } else if (authenticationMethod.isSaml && self.businessLogic.isSignedIn) {
    // if authentication method is SAML and user is already logged, the only possible action is to logout
    // add login/logout button, it will detect by itself that it should be log out in this case
    authCells = @[@(CellKindLogInSignOut)];
  } else if (authenticationMethod.isSaml) {
    // if authentication method is SAML and previous case wasn't fullfilled, make a list of all possible IDPs to login
    NSMutableArray *multipleCells = @[].mutableCopy;
    for (OPDS2SamlIDP *idp in authenticationMethod.samlIdps) {
      NYPLSamlIdpCellType *idpCell = [[NYPLSamlIdpCellType alloc] initWithIdp:idp];
      [multipleCells addObject:idpCell];
    }
    authCells = multipleCells;
  } else if (authenticationMethod.pinKeyboard != LoginKeyboardNone) {
    // if authentication method has an information about pin keyboard, the login method is requires a pin
    authCells = @[@(CellKindBarcode), @(CellKindPIN), @(CellKindLogInSignOut)];
  } else {
    // if all other cases failed, it means that server expects just a barcode, with a blank pin
    self.PINTextField.text = @"";
    authCells = @[@(CellKindBarcode), @(CellKindLogInSignOut)];
  }

  return authCells;
}

- (NSArray *) accountInfoSection {
  NSMutableArray *workingSection = @[].mutableCopy;
  if (self.businessLogic.selectedAuthentication.needsAgeCheck) {
    workingSection = @[@(CellKindAgeCheck)].mutableCopy;
  } else if (!self.businessLogic.selectedAuthentication.needsAuth) {
    // no authentication needed, empty section

  } else if (self.businessLogic.selectedAuthentication && self.businessLogic.isSignedIn) {
    // user already logged in
    // show only the selected auth method

    [workingSection addObjectsFromArray:[self cellsForAuthMethod:self.businessLogic.selectedAuthentication]];
  } else if (!self.businessLogic.isSignedIn && self.businessLogic.userAccount.needsAuth) {
    // user needs to sign in

    if (self.businessLogic.isSamlPossible) {
      // TODO: SIMPLY-2884 add an information header that authentication is required
      NSString *libraryInfo = [NSString stringWithFormat:@"Log in to %@ required to download books.", self.businessLogic.libraryAccount.name];
      [workingSection addObject:[[NYPLInfoHeaderCellType alloc] initWithInformation:libraryInfo]];
    }

    if (self.businessLogic.libraryAccount.details.auths.count > 1) {
      // multiple authentication methods
      for (AccountDetailsAuthentication *authenticationMethod in self.businessLogic.libraryAccount.details.auths) {
        // show all possible login methods
        NYPLAuthMethodCellType *autheticationCell = [[NYPLAuthMethodCellType alloc] initWithAuthenticationMethod:authenticationMethod];
        [workingSection addObject:autheticationCell];
        if (authenticationMethod.methodDescription == self.businessLogic.selectedAuthentication.methodDescription) {
          // selected method, unfold
          [workingSection addObjectsFromArray:[self cellsForAuthMethod:authenticationMethod]];
        }
      }
    } else if (self.businessLogic.libraryAccount.details.auths.count == 1) {
      // only 1 authentication method
      // no method header needed
      [workingSection addObjectsFromArray:[self cellsForAuthMethod:self.businessLogic.libraryAccount.details.auths[0]]];
    } else if (self.businessLogic.selectedAuthentication) {
      // only 1 authentication method
      // no method header needed
      [workingSection addObjectsFromArray:[self cellsForAuthMethod:self.businessLogic.selectedAuthentication]];
    }
  } else {
    [workingSection addObjectsFromArray:[self cellsForAuthMethod:self.businessLogic.selectedAuthentication]];
  }

  if ([self.businessLogic librarySupportsBarcodeDisplay]) {
    [workingSection insertObject:@(CellKindBarcodeImage) atIndex: 0];
  }

  return workingSection;
}

- (void)setupTableData
{
  NSArray *section0AcctInfo = [self accountInfoSection];

  NSMutableArray *section2About = [[NSMutableArray alloc] init];
  if ([self.selectedAccount.details getLicenseURL:URLTypePrivacyPolicy]) {
    [section2About addObject:@(CellKindPrivacyPolicy)];
  }
  if ([self.selectedAccount.details getLicenseURL:URLTypeContentLicenses]) {
    [section2About addObject:@(CellKindContentLicense)];
  }
  NSMutableArray *section1Sync = [[NSMutableArray alloc] init];
  if ([self.businessLogic shouldShowSyncButton]) {
    [section1Sync addObject:@(CellKindSyncButton)];
    [section2About addObject:@(CellKindAdvancedSettings)];
  }
  
  if ([self.businessLogic registrationIsPossible]) {
    self.tableData = @[section0AcctInfo, @[@(CellKindRegistration)], section1Sync].mutableCopy;
  } else {
    self.tableData = @[section0AcctInfo, section1Sync].mutableCopy;
  }

  if ([self.businessLogic juvenileCardsManagementIsPossible]) {
    [self.tableData addObject:@[@(CellKindJuvenile)]];
  }

  if (self.selectedAccount.supportEmail != nil) {
    [self.tableData addObject:@[@(CellReportIssue)]];
  }
  
  [self.tableData addObject:section2About];

  // compute final tableview contents, adding all non-empty sections
  NSMutableArray *finalTableContents = [[NSMutableArray alloc] init];
  for (NSArray *section in self.tableData) {
    if ([section count] != 0) {
      [finalTableContents addObject:section];
    }
  }
  self.tableData = finalTableContents;
  [self.tableView reloadData];
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

- (void)viewWillTransitionToSize:(__unused CGSize)size
       withTransitionCoordinator:(__unused id<UIViewControllerTransitionCoordinator>)coordinator
{
  [self.tableView reloadData];
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

#pragma mark - NYPLSettingsAccountUIDelegate

- (NSString *)username
{
  return self.usernameTextField.text;
}

- (NSString *)pin
{
  return self.PINTextField.text;
}

#pragma mark - Account SignIn/SignOut

- (void)logIn
{
  if (self.businessLogic.selectedAuthentication.isOauth) {
    // oauth
    [self oauthLogIn];
  } else if (self.businessLogic.selectedAuthentication.isSaml) {
    // SAML
    [self samlLogIn];
  } else {
    // bar and pin
    [self barcodeLogIn];
  }
}

- (void)oauthLogIn
{
  // for this kind of authentication, we want to redirect user to Safari to conduct the process
  NSURL *oauthURL = self.businessLogic.selectedAuthentication.oauthIntermediaryUrl;

  NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithURL:oauthURL resolvingAgainstBaseURL:true];

  // add params
  NSURLQueryItem *redirect_uri = [[NSURLQueryItem alloc] initWithName:@"redirect_uri" value:NYPLSettings.shared.authenticationUniversalLink.absoluteString];
  urlComponents.queryItems = [urlComponents.queryItems arrayByAddingObject:redirect_uri];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleRedirectURL:)
                                               name: NSNotification.NYPLAppDelegateDidReceiveCleverRedirectURL
                                             object:nil];

  [UIApplication.sharedApplication openURL:urlComponents.URL
                                   options:@{}
                         completionHandler:nil];

  [[UIApplication sharedApplication] beginIgnoringInteractionEvents];

}

- (void)samlLogIn
{
  // for this kind of authentication, we want user to authenticate in a built in webview, as we need to access the cookies later on

  // get the url of IDP that user selected
  NSURL *idpURL = self.businessLogic.selectedIDP.url;

  NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithURL:idpURL resolvingAgainstBaseURL:true];

  // add redirect uri param
  NSURLQueryItem *redirect_uri = [[NSURLQueryItem alloc] initWithName:@"redirect_uri" value:NYPLSettings.shared.authenticationUniversalLink.absoluteString];
  urlComponents.queryItems = [urlComponents.queryItems arrayByAddingObject:redirect_uri];
  NSURL *url = urlComponents.URL;

  void (^loginCompletionHandler)(NSURL * _Nonnull, NSArray<NSHTTPCookie *> * _Nonnull) = ^(NSURL * _Nonnull url, NSArray<NSHTTPCookie *> * _Nonnull cookies) {
    // when user login successfully, get cookies
    self.cookies = cookies;

    // process the last redirection url to get the oauth token
    [self handleRedirectURL:[NSNotification notificationWithName:NSNotification.NYPLAppDelegateDidReceiveCleverRedirectURL
                                                          object:url
                                                        userInfo:nil]];

    // and close the webview
    [self dismissViewControllerAnimated:YES completion:nil];
  };

  // create a model for webview authentication process
  NYPLCookiesWebViewModel *model = [[NYPLCookiesWebViewModel alloc] initWithCookies:@[]
                                                                            request:[[NSURLRequest alloc] initWithURL:url]
                                                             loginCompletionHandler:loginCompletionHandler
                                                                 loginCancelHandler:nil
                                                                   bookFoundHandler:nil
                                                                problemFoundHandler:nil
                                                                autoPresentIfNeeded:NO];

  NYPLCookiesWebViewController *cookiesVC = [[NYPLCookiesWebViewController alloc] initWithModel:model];
  UINavigationController *navigationWrapper = [[UINavigationController alloc] initWithRootViewController:cookiesVC];
  [self presentViewController:navigationWrapper animated:YES completion:nil];
}

- (void)barcodeLogIn
{
  assert(self.usernameTextField.text.length > 0);
  assert(self.PINTextField.text.length > 0 || [self.PINTextField.text isEqualToString:@""]);

  [self.usernameTextField resignFirstResponder];
  [self.PINTextField resignFirstResponder];

  [self setActivityTitleWithText:NSLocalizedString(@"Verifying", nil)];

  [self validateCredentials];
}

- (void) handleRedirectURL: (NSNotification *) notification
{
  [NSNotificationCenter.defaultCenter removeObserver: self name: NSNotification.NYPLAppDelegateDidReceiveCleverRedirectURL object: nil];

  NSURL *url = notification.object;
  if (![url.absoluteString hasPrefix:NYPLSettings.shared.authenticationUniversalLink.absoluteString]
      || !([url.absoluteString containsString:@"error"] || ([url.absoluteString containsString:@"access_token"] && [url.absoluteString containsString:@"patron_info"])))
  {
    // received neither error, nor login data, something's wrong
    [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeUnrecognizedLoginUniversalLink
                              summary:@"SignIn-settingsTab"
                              message:@"App received login finished universal link, but no necessary data inside."
                             metadata:@{
                               @"loginUrl": url.absoluteString
                             }];

    // TODO: SIMPLY-2884 validate this string with product
    [self displayErrorMessage:
     NSLocalizedString(@"An error occurred during the authentication process",
                       @"Generic error message while handling sign-in redirection during authentication")];
    return;
  }

  NSMutableDictionary *kvpairs = [[NSMutableDictionary alloc] init];
  // Oauth2Intermediate auth method may provide the auth token in fragment
  // instead of query parameter
  NSString *responseData = url.fragment != nil ? url.fragment : url.query;
  for (NSString *param in [responseData componentsSeparatedByString:@"&"]) {
    NSArray *elts = [param componentsSeparatedByString:@"="];
    if([elts count] < 2) continue;
    [kvpairs setObject:[elts lastObject] forKey:[elts firstObject]];
  }

  NSString *rawError = kvpairs[@"error"];
  if (rawError) {
    NSString *error = [[rawError stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByRemovingPercentEncoding];

    NSDictionary *parsedError = [error parseJSONString];
    if (parsedError) {
      [self displayErrorMessage:parsedError[@"title"]];
    }

    [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeSignInRedirectError
                              summary:NSStringFromClass([self class])
                              message:@"An error was encountered while handling Sign-In redirection"
                             metadata:@{
                               NSUnderlyingErrorKey: rawError ?: @"N/A",
                               @"redirectURL": url ?: @"N/A"
                             }];
  }

  NSString *auth_token = kvpairs[@"access_token"];
  NSString *patron_info = kvpairs[@"patron_info"];

  if (auth_token != nil && patron_info != nil) {
    NSString *patron = [[patron_info stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByRemovingPercentEncoding];

    NSDictionary *parsedPatron = [patron parseJSONString];
    if (parsedPatron) {
      self.authToken = auth_token;
      self.patron = parsedPatron;
      [self validateCredentials];
    } else {
      // login succeeded, but I couldn't parse the patron info
      [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeOauthPatronInfoDecodeFail
                                summary:@"SignIn-settingsTab"
                                message:@"App couldn't parse the patron info delivered in oauth/saml redirection."
                               metadata:@{
                                 @"patronInfo": patron
                               }];
    }
  }
}

- (void)logOut
{
  UIAlertController *alert = [self.businessLogic logOutOrWarnUsing:self];
  if (alert) {
    [self presentViewController:alert animated:YES completion:nil];
  }
}

- (void)performLogOut
{
#if defined(FEATURE_DRM_CONNECTOR)

  [self setActivityTitleWithText:NSLocalizedString(@"SigningOut", nil)];
  [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
  
  
  // Get a fresh licensor token before attempting to deauthorize
  NSMutableURLRequest *const request =
  [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[[self.selectedAccount details] userProfileUrl]]];
  
  request.timeoutInterval = self.businessLogic.requestTimeoutInterval;
  
  NSString * const currentBarcode = [[self selectedUserAccount] barcode];
  NSURLSessionDataTask *const task =
  [self.session
   dataTaskWithRequest:request
   completionHandler:^(NSData *data,
                       NSURLResponse *const response,
                       NSError *const error) {
     
     NSInteger statusCode = ((NSHTTPURLResponse *) response).statusCode;
     if (statusCode == 200) {
       NSError *pDocError = nil;
       UserProfileDocument *pDoc = [UserProfileDocument fromData:data error:&pDocError];
       if (!pDoc) {
         [NYPLErrorLogger logUserProfileDocumentAuthError:pDocError
                                                  summary:@"signOut: unable to parse user profile doc"
                                                  barcode:currentBarcode];
         [self showLogoutAlertWithError:pDocError responseCode:statusCode];
         [self removeActivityTitle];
         [[UIApplication sharedApplication] endIgnoringInteractionEvents];
       } else {
         if (pDoc.drm.count > 0 && pDoc.drm[0].vendor && pDoc.drm[0].clientToken) {
           [self.selectedUserAccount setLicensor:[pDoc.drm[0] licensor]];
           NYPLLOG_F(@"\nLicensor Token Updated: %@\nFor account: %@", pDoc.drm[0].clientToken, self.selectedUserAccount.userID);
         } else {
           NYPLLOG_F(@"\nLicensor Token Invalid: %@", [pDoc toJson])
         }
         [self deauthorizeDevice]; // will call endIgnoringInteractionEvents

#ifdef OPENEBOOKS
         [NYPLSettings sharedSettings].accountMainFeedURL = nil;
#endif
       }
     } else {
       if (statusCode == 401) {
         [self deauthorizeDevice];
       }

       NSString *msg = [NSString stringWithFormat:@"Error signing out for barcode %@",
                        currentBarcode.md5String];
       [NYPLErrorLogger logNetworkError:error
                                   code:NYPLErrorCodeApiCall
                                summary:@"signOut"
                                request:request
                               response:response
                                message:msg
                               metadata:nil];
       [self showLogoutAlertWithError:error responseCode:statusCode];
       [self removeActivityTitle];
       [[UIApplication sharedApplication] endIgnoringInteractionEvents];
     }
   }];

  [task resume];
  
#else

  if([NYPLBookRegistry sharedRegistry].syncing == YES) {
    [self presentViewController:[NYPLAlertUtils
                                 alertWithTitle:@"SettingsAccountViewControllerCannotLogOutTitle"
                                 message:@"SettingsAccountViewControllerCannotLogOutMessage"]
                       animated:YES
                     completion:nil];
  } else {
    [[NYPLMyBooksDownloadCenter sharedDownloadCenter] reset:self.selectedAccountId];
    [[NYPLBookRegistry sharedRegistry] reset:self.selectedAccountId];
    [self.businessLogic.userAccount removeAll];
    self.businessLogic.selectedIDP = nil;
    [self setupTableData];
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
    
    [self.businessLogic.userAccount removeAll];
    self.businessLogic.selectedIDP = nil;
    [self setupTableData];
  };

  NSDictionary *licensor = [self.selectedUserAccount licensor];
  if (!licensor) {
    NYPLLOG(@"No Licensor available to deauthorize device. Signing out NYPLAccount creds anyway.");
    [NYPLErrorLogger logInvalidLicensorWithAccountID:self.selectedAccountId];
    afterDeauthorization();
    return;
  }

  NSMutableArray *licensorItems = [[licensor[@"clientToken"] stringByReplacingOccurrencesOfString:@"\n" withString:@""] componentsSeparatedByString:@"|"].mutableCopy;
  NSString *tokenPassword = [licensorItems lastObject];
  [licensorItems removeLastObject];
  NSString *tokenUsername = [licensorItems componentsJoinedByString:@"|"];
  NSString *deviceID = [self.selectedUserAccount deviceID];
  
  NYPLLOG(@"***DRM Deactivation Attempt***");
  NYPLLOG_F(@"\nLicensor: %@\n",licensor);
  NYPLLOG_F(@"Token Username: %@\n",tokenUsername);
  NYPLLOG_F(@"Token Password: %@\n",tokenPassword);
  NYPLLOG_F(@"UserID: %@\n",[self.selectedUserAccount userID]);
  NYPLLOG_F(@"DeviceID: %@\n",deviceID);
  
  [[NYPLADEPT sharedInstance]
   deauthorizeWithUsername:tokenUsername
   password:tokenPassword
   userID:[self.selectedUserAccount userID]
   deviceID:deviceID
   completion:^(BOOL success, NSError *error) {
     
     if(!success) {
       // Even though we failed, let the user continue to log out.
       // The most likely reason is a user changing their PIN.
       [NYPLErrorLogger logError:error
                         summary:@"User lost an activation on signout: ADEPT error"
                         message:nil
                        metadata:@{
                          @"DeviceID": deviceID ?: @"N/A",
                          @"Licensor": licensor ?: @"N/A",
                          @"AdobeTokenUsername": tokenUsername,
                          @"AdobeTokenPassword": tokenPassword,
                        }];
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
  [[UIApplication sharedApplication] beginIgnoringInteractionEvents];

  NSMutableURLRequest *const request =
  [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[[self.selectedAccount details] userProfileUrl]]];

  request.timeoutInterval = self.businessLogic.requestTimeoutInterval;

  if (self.businessLogic.selectedAuthentication.isOauth || self.businessLogic.selectedAuthentication.isSaml) {
    if (self.authToken) {
      NSString *authenticationValue = [@"Bearer " stringByAppendingString: self.authToken];
      [request addValue:authenticationValue forHTTPHeaderField:@"Authorization"];
    } else {
      NYPLLOG(@"Auth token expected, but none is available.");
      [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeValidationWithoutAuthToken
                                summary:@"SignIn-settingsTab"
                                message:@"There is no token available during oauth/saml authentication validation."
                               metadata:nil];
    }
  }

  __weak __auto_type weakSelf = self;
  NSURLSessionDataTask *const task =
  [self.session
   dataTaskWithRequest:request
   completionHandler:^(NSData *data,
                       NSURLResponse *const response,
                       NSError *const error) {
    NSInteger const statusCode = ((NSHTTPURLResponse *) response).statusCode;

    // all methods methods below call UIApplication::endIgnoringInteractionEvents
    if (statusCode == 200) {
#if defined(FEATURE_DRM_CONNECTOR)
      [weakSelf processCredsValidationSuccessUsingDRMWithData:data];
#else
      [weakSelf authorizationAttemptDidFinish:YES error:nil errorMessage:nil];
#endif
    } else {
      [weakSelf processCredsValidationFailureWithData:data
                                                error:error
                                           forRequest:request
                                             response:response];
    }
  }];
  
  [task resume];
}

#if defined(FEATURE_DRM_CONNECTOR)
// This will call UIApplication::endIgnoringInteractionEvents although it may
// do so asynchronously.
- (void)processCredsValidationSuccessUsingDRMWithData:(NSData*)data
{
  NSError *pDocError = nil;
  NSString * const barcode = self.usernameTextField.text;
  UserProfileDocument *pDoc = [UserProfileDocument fromData:data error:&pDocError];
  if (!pDoc) {
    [self authorizationAttemptDidFinish:NO
                                  error:nil
                           errorMessage:@"Error parsing user profile document"];
    [NYPLErrorLogger logUserProfileDocumentAuthError:pDocError
                                             summary:@"SignIn-settingsTab: unable to parse user profile doc"
                                             barcode:barcode];
    return;
  }

  if (pDoc.authorizationIdentifier) {
    [self.businessLogic.userAccount setAuthorizationIdentifier:pDoc.authorizationIdentifier];
  } else {
    NYPLLOG(@"Authorization ID (Barcode String) was nil.");
    [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeNoAuthorizationIdentifier
                              summary:@"SignIn-settingsTab"
                              message:@"The UserProfileDocument obtained from the server contained no authorization identifier."
                             metadata:@{
                               @"hashedBarcode": barcode.md5String
                             }];
  }

  if (pDoc.drm.count > 0 && pDoc.drm[0].vendor && pDoc.drm[0].clientToken) {
    [self.selectedUserAccount setLicensor:[pDoc.drm[0] licensor]];
  } else {
    NYPLLOG(@"Login Failed: No Licensor Token received or parsed from user profile document");
    [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeNoLicensorToken
                              summary:@"SignIn-settingsTab"
                              message:@"The UserProfileDocument obtained from the server contained no licensor token."
                             metadata:@{
                               @"hashedBarcode": barcode.md5String
                             }];

    [self authorizationAttemptDidFinish:NO
                                  error:nil
                           errorMessage:@"No credentials were received to authorize access to books with DRM."];
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
   authorizeWithVendorID:[self.selectedUserAccount licensor][@"vendor"]
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
        [self.selectedUserAccount setUserID:userID];
        [self.selectedUserAccount setDeviceID:deviceID];
      }];
    } else {
      [NYPLErrorLogger logLocalAuthFailedWithError:error
                                           library:self.selectedAccount
                                          metadata:@{
                                            @"hashedBarcode": barcode.md5String
                                          }];
    }

    [self authorizationAttemptDidFinish:success error:error errorMessage:nil];
  }];
}
#endif

- (void)processCredsValidationFailureWithData:(NSData * const)data
                                        error:(NSError * const)error
                                   forRequest:(NSURLRequest * const)request
                                     response:(NSURLResponse * const)response
{
  NSString * const barcode = self.usernameTextField.text;
  [self removeActivityTitle];
  [[UIApplication sharedApplication] endIgnoringInteractionEvents];

  if (error.code == NSURLErrorCancelled) {
    // We cancelled the request when asked to answer the server's challenge a second time
    // because we don't have valid credentials.
    self.PINTextField.text = @"";
    [self textFieldsDidChange];
    [self.PINTextField becomeFirstResponder];
  }

  NYPLProblemDocument *problemDocument = nil;
  UIAlertController *alert = nil;
  NSError *problemDocumentParseError = nil;
  if (response.isProblemDocument) {
    problemDocument = [NYPLProblemDocument fromData:data
                                              error:&problemDocumentParseError];
    if (problemDocumentParseError == nil && problemDocument != nil) {
      NSString *msg = NSLocalizedString(@"A server error occurred. Please try again later, and if the problem persists, contact your library's Help Desk.", @"Error message for when a server error occurs.");
      NSString *errorDetails = (problemDocument.detail ?: problemDocument.title);
      if (errorDetails) {
        msg = [NSString stringWithFormat:@"%@\n\n(Error details: %@)", msg,
               errorDetails];
      }
      alert = [NYPLAlertUtils alertWithTitle:@"SettingsAccountViewControllerLoginFailed"
                                     message:msg];
      [NYPLAlertUtils setProblemDocumentWithController:alert
                                              document:problemDocument
                                                append:YES];
    }
  }

  // error logging
  if (problemDocumentParseError != nil) {
    [NYPLErrorLogger logProblemDocumentParseError:problemDocumentParseError
                              problemDocumentData:data
                                          barcode:barcode
                                              url:request.URL
                                          summary:@"SettingsAccountDetailVC-processCreds: Problem Doc parse error"
                                          message:@"Sign-in failed, got a corrupted problem doc"];
  } else if (problemDocument) {
    [NYPLErrorLogger logLoginError:error
                           barcode:barcode
                           library:self.selectedAccount
                           request:request
                          response:response
                   problemDocument:problemDocument
                          metadata:@{
                            @"message": @"Sign-in failed, got a problem doc"
                          }];
  }

  // notify user of error
  if (alert == nil) {
    alert = [NYPLAlertUtils alertWithTitle:@"SettingsAccountViewControllerLoginFailed"
                                     error:error];
  }
  [[NYPLRootTabBarController sharedController] safelyPresentViewController:alert
                                                                  animated:YES
                                                                completion:nil];
}

- (void)showLogoutAlertWithError:(NSError *)error responseCode:(NSInteger)code
{
  NSString *title; NSString *message;
  if (code == 401) {
    title = @"Unexpected Credentials";
    message = @"Your username or password may have changed since the last time you logged in.\n\nIf you believe this is an error, please contact your library.";
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

/**
 @note This method is not doing any logging in case `success` is false.

 @param success Whether Adobe DRM authorization was successful or not.
 @param error If errorMessage is absent, this will be used to derive a message
 to present to the user.
 @param errorMessage Will be presented to the user and will be used as a
 localization key to attempt to localize it.
 */
- (void)authorizationAttemptDidFinish:(BOOL)success
                                error:(NSError *)error
                         errorMessage:(NSString*)errorMessage
{
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [self removeActivityTitle];
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    
    if (success) {
      if (self.businessLogic.selectedAuthentication.isOauth) {
        [self.businessLogic.userAccount setAuthToken:self.authToken];
        [self.businessLogic.userAccount setPatron:self.patron];
      } else if (self.businessLogic.selectedAuthentication.isSaml) {
        [self.businessLogic.userAccount setAuthToken:self.authToken];
        [self.businessLogic.userAccount setPatron:self.patron];
        if (self.cookies) {
          [self.businessLogic.userAccount setCookies:self.cookies];
        }
      } else {
        [self.businessLogic.userAccount setBarcode:self.usernameTextField.text PIN:self.PINTextField.text];
      }

      self.businessLogic.userAccount.authDefinition = self.businessLogic.selectedAuthentication;

      if ([self.selectedAccountId isEqualToString:[AccountsManager shared].currentAccount.uuid]) {
        [[NYPLBookRegistry sharedRegistry] syncResettingCache:NO completionHandler:^(BOOL success) {
          if (success) {
            [[NYPLBookRegistry sharedRegistry] save];
          }
        }];
      }
    } else {
      [[NSNotificationCenter defaultCenter] postNotificationName:NSNotification.NYPLSyncEnded object:nil];

      UIAlertController *vc;
      if (errorMessage) {
        vc = [NYPLAlertUtils
              alertWithTitle:@"SettingsAccountViewControllerLoginFailed"
              message:errorMessage];
      } else {
        vc = [NYPLAlertUtils
              alertWithTitle:@"SettingsAccountViewControllerLoginFailed"
              error:error];
      }

      [[NYPLRootTabBarController sharedController]
       safelyPresentViewController:vc
       animated:YES
       completion:nil];
    }
  }];
}

#pragma mark - UITableViewDataSource / UITableViewDelegate + related methods

- (void)tableView:(__attribute__((unused)) UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *const)indexPath
{

  NSArray *sectionArray = (NSArray *)self.tableData[indexPath.section];
  if ([sectionArray[indexPath.row] isKindOfClass:[NYPLAuthMethodCellType class]]) {
    NYPLAuthMethodCellType *methodCell = sectionArray[indexPath.row];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    self.businessLogic.selectedIDP = nil;
    self.businessLogic.selectedAuthentication = methodCell.authenticationMethod;
    [self setupTableData];
    return;
  } else if ([sectionArray[indexPath.row] isKindOfClass:[NYPLSamlIdpCellType class]]) {
    NYPLSamlIdpCellType *idpCell = sectionArray[indexPath.row];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    self.businessLogic.selectedIDP = idpCell.idp;
    [self logIn];
    return;
  } else if ([sectionArray[indexPath.row] isKindOfClass:[NYPLInfoHeaderCellType class]]) {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    return;
  }

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
      if([self.selectedUserAccount hasCredentials]) {
        if ([self.businessLogic shouldShowSyncButton] && !self.syncSwitch.on) {
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
                                    actionWithTitle:NSLocalizedString(@"SignOut", @"Title for sign out action")
                                    style:UIAlertActionStyleDestructive
                                    handler:^(__attribute__((unused)) UIAlertAction *action) {
                                      [self logOut];
                                    }]];
        [alertController addAction:[UIAlertAction
                                    actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                    style:UIAlertActionStyleCancel
                                    handler:nil]];
        [self presentViewController:alertController animated:YES completion:^{
          alertController.view.tintColor = [NYPLConfiguration mainColor];
        }];
      } else {
        [self logIn];
      }
      break;
    }
    case CellKindRegistration: {
      [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
      
      if (self.selectedAccount.details.supportsCardCreator
          && self.selectedAccount.details.signUpUrl != nil) {
        __weak NYPLSettingsAccountDetailViewController *const weakSelf = self;

        CardCreatorConfiguration *config = [self.businessLogic makeRegularCardCreationConfiguration];
        config.completionHandler = ^(NSString *const username, NSString *const PIN, BOOL const userInitiated) {
          if (userInitiated) {
            // Dismiss CardCreator when user finishes Credential Review
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
          } else {
            weakSelf.usernameTextField.text = username;
            weakSelf.PINTextField.text = PIN;
            [weakSelf updateLoginLogoutCellAppearance];
            weakSelf.isLoggingInAfterSignUp = YES;
            [weakSelf logIn];
          }
        };

        UINavigationController *const navController = [CardCreator initialNavigationControllerWithConfiguration:config];
        navController.navigationBar.topItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(didSelectCancelForSignUp)];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:navController animated:YES completion:nil];
      }
      else // does not support card creator
      {
        if (self.selectedAccount.details.signUpUrl == nil) {
          // this situation should be impossible, but let's log it if it happens
          [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeNilSignUpURL
                                    summary:@"SignUp Error in Settings: nil signUp URL"
                                    message:nil
                                   metadata:@{
                                     @"selectedLibraryAccountUUID": self.selectedAccount.uuid,
                                     @"selectedLibraryAccountName": self.selectedAccount.name,
                                   }];
          return;
        }

        RemoteHTMLViewController *webVC =
        [[RemoteHTMLViewController alloc]
         initWithURL:self.selectedAccount.details.signUpUrl
         title:@"eCard"
         failureMessage:NSLocalizedString(@"SettingsConnectionFailureMessage", nil)];
        
        UINavigationController *const navigationController = [[UINavigationController alloc] initWithRootViewController:webVC];
        
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
    case CellKindJuvenile: {
      [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
      UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
      [self didSelectJuvenileSignupOnCell:cell];
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
      if (self.barcodeImageView.bounds.size.height > sConstantZero) {
        self.barcodeHeightConstraint.constant = sConstantZero;
        self.barcodeTextHeightConstraint.constant = sConstantZero;
        self.barcodeTextLabelSpaceConstraint.constant = sConstantZero;
        self.barcodeLabelSpaceConstraint.constant = sConstantZero;
        self.barcodeImageLabel.text = NSLocalizedString(@"Show Barcode", nil);
        [[UIScreen mainScreen] setBrightness:self.userBrightnessSetting];
      } else {
        self.barcodeHeightConstraint.constant = 100.0;
        self.barcodeTextHeightConstraint.constant = 30.0;
        self.barcodeTextLabelSpaceConstraint.constant = -sConstantSpacing;
        self.barcodeLabelSpaceConstraint.constant = -sConstantSpacing;
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

- (UITableViewCell *)setUpJuvenileFlowCell
{
  UITableViewCell *cell = [[UITableViewCell alloc]
                           initWithStyle:UITableViewCellStyleDefault
                           reuseIdentifier:nil];
  cell.textLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
  cell.textLabel.text = NSLocalizedString(@"Want a card for your child?", nil);
  [self addActivityIndicatorToJuvenileCell:cell];
  return cell;
}

- (void)addActivityIndicatorToJuvenileCell:(UITableViewCell *)cell
{
  UIActivityIndicatorViewStyle style;
  if (@available(iOS 13, *)) {
    style = UIActivityIndicatorViewStyleMedium;
  } else {
    style = UIActivityIndicatorViewStyleGray;
  }
  self.juvenileActivityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
  self.juvenileActivityView.center = CGPointMake(cell.bounds.size.width / 2,
                                                 cell.bounds.size.height / 2);
  [self.juvenileActivityView integralizeFrame];
  self.juvenileActivityView.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin |
                                                UIViewAutoresizingFlexibleRightMargin |
                                                UIViewAutoresizingFlexibleBottomMargin |
                                                UIViewAutoresizingFlexibleLeftMargin);
  self.juvenileActivityView.hidesWhenStopped = YES;
  [cell addSubview:self.juvenileActivityView];

  if (self.businessLogic.juvenileAuthIsOngoing) {
    [cell setUserInteractionEnabled:NO];
    cell.textLabel.hidden = YES;
    [self.juvenileActivityView startAnimating];
  } else {
    [cell setUserInteractionEnabled:YES];
    cell.textLabel.hidden = NO;
    [self.juvenileActivityView stopAnimating];
  }
}

- (void)didSelectJuvenileSignupOnCell:(UITableViewCell *)cell
{
  [cell setUserInteractionEnabled:NO];
  cell.textLabel.hidden = YES;
  [self.juvenileActivityView startAnimating];

  __weak __auto_type weakSelf = self;
  [self.businessLogic startJuvenileCardCreationWithEligibilityCompletion:^(UINavigationController * _Nullable navVC, NSError * _Nullable error) {

    [weakSelf.juvenileActivityView stopAnimating];
    cell.textLabel.hidden = NO;
    [cell setUserInteractionEnabled:YES];

    if (error) {
      UIAlertController *alert = [NYPLAlertUtils
                                  alertWithTitle:NSLocalizedString(@"Error", "Alert title")
                                  error:error];
      [NYPLAlertUtils presentFromViewControllerOrNilWithAlertController:alert
                                                         viewController:nil
                                                               animated:YES
                                                             completion:nil];
      return;
    }

    navVC.navigationBar.topItem.leftBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                     style:UIBarButtonItemStylePlain
                                    target:weakSelf
                                    action:@selector(didSelectCancelForSignUp)];
    navVC.modalPresentationStyle = UIModalPresentationFormSheet;
    [weakSelf presentViewController:navVC animated:YES completion:nil];

  } flowCompletion:^{
    [weakSelf dismissViewControllerAnimated:YES completion:nil];
  }];
}

- (void)didSelectCancelForSignUp
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (UITableViewCell *)tableView:(__attribute__((unused)) UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *const)indexPath
{
  NSArray *sectionArray = (NSArray *)self.tableData[indexPath.section];

  if ([sectionArray[indexPath.row] isKindOfClass:[NYPLAuthMethodCellType class]]) {
    NYPLAuthMethodCellType *methodCell = sectionArray[indexPath.row];
    UITableViewCell *cell = [[UITableViewCell alloc]
                             initWithStyle:UITableViewCellStyleDefault
                             reuseIdentifier:nil];
    cell.textLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
    cell.textLabel.text = methodCell.authenticationMethod.methodDescription;
    return cell;
  } else if ([sectionArray[indexPath.row] isKindOfClass:[NYPLSamlIdpCellType class]]) {
    NYPLSamlIdpCellType *idpCell = sectionArray[indexPath.row];
    NYPLSamlIDPCell *cell = [[NYPLSamlIDPCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.idpName.text = idpCell.idp.displayName;
    return cell;
  } else if ([sectionArray[indexPath.row] isKindOfClass:[NYPLInfoHeaderCellType class]]) {
    NYPLInfoHeaderCellType *infoCell = sectionArray[indexPath.row];
    NYPLLibraryDescriptionCell *cell = [[NYPLLibraryDescriptionCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.descriptionLabel.text = infoCell.information;
    return cell;
  }

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
                                           withOffset:sVerticalMarginPadding];
        [self.usernameTextField autoConstrainAttribute:ALAttributeBottom toAttribute:ALAttributeMarginBottom
                                               ofView:[self.usernameTextField superview]
                                           withOffset:-sVerticalMarginPadding];

        if (self.businessLogic.selectedAuthentication.supportsBarcodeScanner) {
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

      if (![self.businessLogic librarySupportsBarcodeDisplay]) {
        NYPLLOG(@"A nonvalid library was attempting to create a barcode image.");
      } else {
        NYPLBarcode *barcode = [[NYPLBarcode alloc] initWithLibrary:self.selectedAccount.name];
        UIImage *barcodeImage = [barcode imageFromString:self.selectedUserAccount.authorizationIdentifier
                                          superviewWidth:self.tableView.bounds.size.width
                                                    type:NYPLBarcodeTypeCodabar];

        if (barcodeImage) {
          self.barcodeImageView = [[UIImageView alloc] initWithImage:barcodeImage];
          self.barcodeImageLabel = [[UILabel alloc] init];
          self.barcodeTextLabel = [[UILabel alloc] init];
          self.barcodeTextLabel.text = self.selectedUserAccount.authorizationIdentifier;
          self.barcodeTextLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
          self.barcodeTextLabel.textAlignment = NSTextAlignmentCenter;
          self.barcodeImageLabel.text = NSLocalizedString(@"Show Barcode", nil);
          self.barcodeImageLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
          self.barcodeImageLabel.textColor = [NYPLConfiguration mainColor];

          [cell.contentView addSubview:self.barcodeImageView];
          [cell.contentView addSubview:self.barcodeTextLabel];
          [cell.contentView addSubview:self.barcodeImageLabel];
          [self.barcodeTextLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
          [self.barcodeTextLabel autoSetDimension:ALDimensionWidth toSize:self.tableView.bounds.size.width];
          [self.barcodeImageView autoAlignAxisToSuperviewAxis:ALAxisVertical];
          [self.barcodeImageView autoSetDimension:ALDimensionWidth toSize:self.tableView.bounds.size.width];
          [NSLayoutConstraint autoSetPriority:UILayoutPriorityRequired forConstraints:^{
            // Hidden to start
            self.barcodeHeightConstraint = [self.barcodeImageView autoSetDimension:ALDimensionHeight toSize:0];
            self.barcodeTextHeightConstraint = [self.barcodeTextLabel autoSetDimension:ALDimensionHeight toSize:0];
            self.barcodeLabelSpaceConstraint = [self.barcodeImageView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.barcodeTextLabel withOffset:0];
            self.barcodeTextLabelSpaceConstraint = [self.barcodeTextLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.barcodeImageLabel withOffset:0];
          }];
          [self.barcodeImageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:sConstantSpacing];
          [self.barcodeImageLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
          [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultHigh forConstraints:^{
            [self.barcodeImageLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:10.0];
          }];
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
      
      UIImageView *accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:(self.selectedAccount.details.userAboveAgeLimit ? @"CheckboxOn" : @"CheckboxOff")]];
      accessoryView.image = [accessoryView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
      accessoryView.tintColor = [UIColor defaultLabelColor];
      self.ageCheckCell.accessoryView = accessoryView;
      
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
    case CellKindJuvenile: {
      return [self setUpJuvenileFlowCell];
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
  regButton.textColor = [NYPLConfiguration mainColor];

  [containerView addSubview:regTitle];
  [containerView addSubview:regButton];
  [regTitle autoPinEdgeToSuperviewMargin:ALEdgeLeft];
  [regTitle autoConstrainAttribute:ALAttributeTop toAttribute:ALAttributeMarginTop ofView:[regTitle superview] withOffset:sVerticalMarginPadding];
  [regTitle autoConstrainAttribute:ALAttributeBottom toAttribute:ALAttributeMarginBottom ofView:[regTitle superview] withOffset:-sVerticalMarginPadding];
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
  if (section == sSection0AccountInfo) {
    return UITableViewAutomaticDimension;
  } else {
    return 0;
  }
}
- (CGFloat)tableView:(__unused UITableView *)tableView heightForFooterInSection:(__unused NSInteger)section
{
  if ((section == sSection0AccountInfo && [self.businessLogic shouldShowEULALink]) ||
      (section == sSection1Sync && [self.businessLogic shouldShowSyncButton])) {
    return UITableViewAutomaticDimension;
  } else {
    return 0;
  }
}
-(CGFloat)tableView:(__unused UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section
{
  if (section == sSection0AccountInfo) {
    return 80;
  } else {
    return 0;
  }
}
- (CGFloat)tableView:(__unused UITableView *)tableView estimatedHeightForFooterInSection:(__unused NSInteger)section
{
  if ((section == sSection0AccountInfo && [self.businessLogic shouldShowEULALink]) ||
      (section == sSection1Sync && [self.businessLogic shouldShowSyncButton])) {
    return 44;
  } else {
    return 0;
  }
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
  if (section == sSection0AccountInfo) {
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

    self.accountInfoHeaderView = containerView;
    return containerView;
  } else {
    return nil;
  }
}

- (UIView *)tableView:(UITableView *)__unused tableView viewForFooterInSection:(NSInteger)section
{
  // something's wrong, it gets called every refresh cycle when scrolling
  if ((section == sSection0AccountInfo && [self.businessLogic shouldShowEULALink]) ||
      (section == sSection1Sync && [self.businessLogic shouldShowSyncButton])) {

    UIView *container = [[UIView alloc] init];
    container.preservesSuperviewLayoutMargins = YES;
    UILabel *footerLabel = [[UILabel alloc] init];
    footerLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleCaption1];
    footerLabel.numberOfLines = 0;
    footerLabel.userInteractionEnabled = YES;

    NSMutableAttributedString *eulaString;
    if (section == sSection0AccountInfo) {
      [footerLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showEULA)]];

      NSDictionary *linkAttributes = @{ NSForegroundColorAttributeName :
                                          [UIColor colorWithRed:0.05 green:0.4 blue:0.65 alpha:1.0],
                                        NSUnderlineStyleAttributeName :
                                          @(NSUnderlineStyleSingle) };
      eulaString = [[NSMutableAttributedString alloc]
                    initWithString:NSLocalizedString(@"SigningInAgree", nil) attributes:linkAttributes];
    } else { // sync section
      NSDictionary *attrs;
      attrs = @{ NSForegroundColorAttributeName : [UIColor defaultLabelColor] };
      eulaString = [[NSMutableAttributedString alloc]
                    initWithString:NSLocalizedString(@"SettingsAccountSyncFooterTitle",
                                                     @"Explain to the user they can save their bookmarks in the cloud across all their devices.")
                    attributes:attrs];
    }
    footerLabel.attributedText = eulaString;

    [container addSubview:footerLabel];
    [footerLabel autoPinEdgeToSuperviewMargin:ALEdgeLeft];
    [footerLabel autoPinEdgeToSuperviewMargin:ALEdgeRight];
    [footerLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:8.0];
    [footerLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:16.0 relation:NSLayoutRelationGreaterThanOrEqual];

    if (section == sSection0AccountInfo) {
      self.accountInfoFooterView = container;
    } else if (section == sSection1Sync) {
      self.syncFooterView = container;
    }

    return container;
  } else {
    return nil;
  }
}

#pragma mark - Text Input

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

#pragma mark -

- (void)PINShowHideSelected
{
  if(self.PINTextField.text.length > 0 && self.PINTextField.secureTextEntry) {
    LAContext *const context = [[LAContext alloc] init];
    if([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:NULL]) {
      [context evaluatePolicy:LAPolicyDeviceOwnerAuthentication
              localizedReason:NSLocalizedString(@"SettingsAccountViewControllerAuthenticationReason", nil)
                        reply:^(BOOL success, NSError *_Nullable error) {
        if(success) {
          [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self togglePINShowHideState];
          }];
        } else {
          [NYPLErrorLogger logError:error
                            summary:@"Show/Hide PIN"
                            message:@"Error while trying to show the PIN"
                           metadata:nil];
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
    if(self.selectedUserAccount.hasCredentials) {
      [self checkSyncPermissionForCurrentPatron];
      self.usernameTextField.text = self.selectedUserAccount.barcode;
      self.usernameTextField.enabled = NO;
      self.usernameTextField.textColor = [UIColor grayColor];
      self.PINTextField.text = self.selectedUserAccount.PIN;
      self.PINTextField.textColor = [UIColor grayColor];
      self.barcodeScanButton.hidden = YES;
    } else {
      self.usernameTextField.text = nil;
      self.usernameTextField.enabled = YES;
      self.usernameTextField.textColor = [UIColor defaultLabelColor];
      self.PINTextField.text = nil;
      self.PINTextField.textColor = [UIColor defaultLabelColor];
      self.barcodeScanButton.hidden = NO;
    }
    
    [self setupTableData];

    [self updateLoginLogoutCellAppearance];
  }];
}

- (void)updateLoginLogoutCellAppearance
{
  if([self.selectedUserAccount hasCredentials]) {
    self.logInSignOutCell.textLabel.text = NSLocalizedString(@"SignOut", @"Title for sign out action");
    self.logInSignOutCell.textLabel.textAlignment = NSTextAlignmentCenter;
    self.logInSignOutCell.textLabel.textColor = [NYPLConfiguration mainColor];
    self.logInSignOutCell.userInteractionEnabled = YES;
  } else {
    self.logInSignOutCell.textLabel.text = NSLocalizedString(@"LogIn", nil);
    self.logInSignOutCell.textLabel.textAlignment = NSTextAlignmentLeft;
    BOOL const barcodeHasText = [self.usernameTextField.text
                                 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length;
    BOOL const pinHasText = [self.PINTextField.text
                             stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length;
    BOOL const pinIsNotRequired = self.businessLogic.selectedAuthentication.pinKeyboard == LoginKeyboardNone;
    BOOL const oauthLogin = self.businessLogic.selectedAuthentication.isOauth;
    if((barcodeHasText && pinHasText) || (barcodeHasText && pinIsNotRequired) || oauthLogin) {
      self.logInSignOutCell.userInteractionEnabled = YES;
      self.logInSignOutCell.textLabel.textColor = [NYPLConfiguration mainColor];
    } else {
      self.logInSignOutCell.userInteractionEnabled = NO;
      if (@available(iOS 13.0, *)) {
        self.logInSignOutCell.textLabel.textColor = [UIColor systemGray2Color];
      } else {
        self.logInSignOutCell.textLabel.textColor = [UIColor lightGrayColor];
      }
    }
  }
}

- (void)setActivityTitleWithText:(NSString *)text
{
  UIActivityIndicatorView *aiv;
  if (@available(iOS 13.0, *)) {
    aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    aiv.color = [UIColor labelColor];
  } else {
    aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  }
  UIActivityIndicatorView *const activityIndicatorView = aiv;
  
  [activityIndicatorView startAnimating];
  
  UILabel *const titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  titleLabel.text = text;
  titleLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
  [titleLabel sizeToFit];
  
  // This view is used to keep the title label centered as in Apple's Settings application.
  UIView *const rightPaddingView = [[UIView alloc] initWithFrame:activityIndicatorView.bounds];
  
  NYPLLinearView *const linearView = [[NYPLLinearView alloc] init];
  linearView.tag = sLinearViewTag;
  linearView.contentVerticalAlignment = NYPLLinearViewContentVerticalAlignmentMiddle;
  linearView.padding = 5.0;
  [linearView addSubview:activityIndicatorView];
  [linearView addSubview:titleLabel];
  [linearView addSubview:rightPaddingView];
  [linearView sizeToFit];
  [linearView autoSetDimensionsToSize:CGSizeMake(linearView.frame.size.width, linearView.frame.size.height)];
  
  self.logInSignOutCell.textLabel.text = nil;
  if (![self.logInSignOutCell.contentView viewWithTag:sLinearViewTag]) {
    [self.logInSignOutCell.contentView addSubview:linearView];
  }
  [linearView autoCenterInSuperview];
}

- (void)removeActivityTitle {
  UIView *view = [self.logInSignOutCell.contentView viewWithTag:sLinearViewTag];
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

- (void)syncSwitchChanged:(UISwitch*)sender
{
  const BOOL currentSwitchState = sender.on;

  if (sender.on) {
    self.syncSwitch.enabled = NO;
  } else {
    self.syncSwitch.on = NO;
  }

  __weak __auto_type weakSelf = self;
  [self.businessLogic changeSyncPermissionTo:currentSwitchState
                    postServerSyncCompletion:^(BOOL success) {
    weakSelf.syncSwitch.enabled = YES;
    weakSelf.syncSwitch.on = success;
  }];
}

- (void)checkSyncPermissionForCurrentPatron
{
  [self.businessLogic checkSyncPermissionWithPreWork:^{
    self.syncSwitch.enabled = NO;
  } postWork:^(BOOL enableSync){
    self.syncSwitch.on = enableSync;
    self.syncSwitch.enabled = YES;
  }];
}

- (void)didSelectCancel
{
  [self.navigationController.presentingViewController
   dismissViewControllerAnimated:YES
   completion:nil];
}

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

@end
