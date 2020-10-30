@import LocalAuthentication;
@import NYPLCardCreator;
@import CoreLocation;

#import <PureLayout/PureLayout.h>

#import "SimplyE-Swift.h"

#import "NYPLAccountSignInViewController.h"
#import "NYPLAppDelegate.h"
#import "NYPLBarcodeScanningViewController.h"
#import "NYPLBookCoverRegistry.h"
#import "NYPLBookRegistry.h"
#import "NYPLConfiguration.h"
#import "NYPLLinearView.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLOPDSFeed.h"
#import "NYPLReachability.h"
#import "NYPLRootTabBarController.h"
#import "NYPLSignInURLSessionChallengeHandler.h"
#import "NYPLSettingsEULAViewController.h"
#import "NYPLXML.h"
#import "UIView+NYPLViewAdditions.h"
#import "UIFont+NYPLSystemFontOverride.h"

#if defined(FEATURE_DRM_CONNECTOR)
#import <ADEPT/ADEPT.h>
#endif

static NSInteger sLinearViewTag = 1111;

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

@interface NYPLAccountSignInViewController () <NYPLUserAccountInputProvider, NYPLSettingsAccountUIDelegate, NYPLSignInBusinessLogicUIDelegate>

// state machine
@property (nonatomic) BOOL loggingInAfterBarcodeScan;
@property (nonatomic) BOOL hiddenPIN;

// UI
@property (nonatomic) UIButton *barcodeScanButton;
@property (nonatomic) UITableViewCell *logInSignOutCell;
@property (nonatomic) UIButton *PINShowHideButton;
@property (nonatomic) NSArray *tableData;

// account state
@property NYPLUserAccountFrontEndValidation *frontEndValidator;
@property (nonatomic) NYPLSignInBusinessLogic *businessLogic;
@property (nonatomic) NSArray *cookies;

// networking
@property (nonatomic) NSURLSession *session;
@property (nonatomic) NYPLSignInURLSessionChallengeHandler *urlSessionDelegate;

@end

@implementation NYPLAccountSignInViewController

@synthesize usernameTextField;
@synthesize PINTextField;

CGFloat const marginPadding = 2.0;

#pragma mark - NYPLSignInBusinessLogicUIDelegate properties

- (NSString *)context
{
  return @"SignIn-modal";
}

#pragma mark - Computed variables

- (Account *)currentAccount
{
  return self.businessLogic.libraryAccount;
}

#pragma mark NSObject

- (instancetype)init
{
  self = [super initWithStyle:UITableViewStyleGrouped];
  if(!self) return nil;

  self.businessLogic = [[NYPLSignInBusinessLogic alloc]
                        initWithLibraryAccountID:AccountsManager.shared.currentAccountId
                        libraryAccountsProvider:AccountsManager.shared
                        universalLinksSettings: NYPLSettings.shared
                        bookRegistry:[NYPLBookRegistry sharedRegistry]
                        userAccountProvider:[NYPLUserAccount class]
                        uiDelegate:self
                        drmAuthorizer:
#if FEATURE_DRM_CONNECTOR
                        [NYPLADEPT sharedInstance]
#else
                        nil
#endif
                        ];

  self.title = NSLocalizedString(@"SignIn", nil);

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
  
  configuration.timeoutIntervalForResource = 15.0;

  _urlSessionDelegate = [[NYPLSignInURLSessionChallengeHandler alloc]
                           initWithUIDelegate:self];

  self.session = [NSURLSession
                  sessionWithConfiguration:configuration
                  delegate:_urlSessionDelegate
                  delegateQueue:[NSOperationQueue mainQueue]];

  self.frontEndValidator = [[NYPLUserAccountFrontEndValidation alloc]
                            initWithAccount:self.currentAccount
                            businessLogic:self.businessLogic
                            inputProvider:self];
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
  self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;

  self.usernameTextField = [[UITextField alloc] initWithFrame:CGRectZero];
  self.usernameTextField.delegate = self.frontEndValidator;
  self.usernameTextField.placeholder = NSLocalizedString(@"BarcodeOrUsername", nil);

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
  
  self.PINTextField = [[UITextField alloc] initWithFrame:CGRectZero];
  self.PINTextField.placeholder = NSLocalizedString(@"PIN", nil);

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

  self.barcodeScanButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.barcodeScanButton setImage:[UIImage imageNamed:@"CameraIcon"] forState:UIControlStateNormal];
  [self.barcodeScanButton addTarget:self action:@selector(scanLibraryCard)
                   forControlEvents:UIControlEventTouchUpInside];

  self.logInSignOutCell = [[UITableViewCell alloc]
                           initWithStyle:UITableViewCellStyleDefault
                           reuseIdentifier:nil];

  [self setupTableData];
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
  if (!self.businessLogic.selectedAuthentication.needsAuth) {
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
      for (AccountDetailsAuthentication *authMethod in self.businessLogic.libraryAccount.details.auths) {
        // show all possible login methods
        NYPLAuthMethodCellType *authType = [[NYPLAuthMethodCellType alloc] initWithAuthenticationMethod:authMethod];
        [workingSection addObject:authType];
        if (authMethod.methodDescription == self.businessLogic.selectedAuthentication.methodDescription) {
          // selected method, unfold
          [workingSection addObjectsFromArray:[self cellsForAuthMethod:authMethod]];
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
  return workingSection;
}

- (void)setupTableData
{
  NSArray *section0AcctInfo = [self accountInfoSection];

  NSArray *section1;
  if ([self.businessLogic registrationIsPossible]) {
    section1 = @[@(CellKindRegistration)];
  } else {
    section1 = @[];
  }
  self.tableData = @[section0AcctInfo, section1];
  [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  // The new credentials are not yet saved after signup or after scanning. As such,
  // reloading the table would lose the values in the barcode and PIN fields.
  if (self.businessLogic.isLoggingInAfterSignUp || self.loggingInAfterBarcodeScan) {
    return;
  } else {
    self.hiddenPIN = YES;
    [self accountDidChange];
    [self updateShowHidePINState];
  }
}

#if defined(FEATURE_DRM_CONNECTOR)
- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];

  NYPLUserAccount *userAccount = self.businessLogic.userAccount;

  if (![[NYPLADEPT sharedInstance] isUserAuthorized:[userAccount userID]
                                         withDevice:[userAccount deviceID]]) {
    if ([userAccount hasBarcodeAndPIN] && !self.businessLogic.isCurrentlySigningIn) {
      self.usernameTextField.text = userAccount.barcode;
      self.PINTextField.text = userAccount.PIN;
      [self.businessLogic logIn];
    }
  }
}
#endif

#pragma mark UITableViewDelegate

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
    [self.businessLogic logIn];
    return;
  } else if ([sectionArray[indexPath.row] isKindOfClass:[NYPLInfoHeaderCellType class]]) {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    return;
  }

  CellKind cellKind = (CellKind)[sectionArray[indexPath.row] intValue];

  switch(cellKind) {
    case CellKindBarcode:
      [self.usernameTextField becomeFirstResponder];
      break;
    case CellKindPIN:
      [self.PINTextField becomeFirstResponder];
      break;
    case CellKindLogInSignOut:
      [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
      [self.businessLogic logIn];
      break;
    case CellKindRegistration: {
      [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
      
      if (self.currentAccount.details.supportsCardCreator
          && self.currentAccount.details.signUpUrl != nil) {
        __weak NYPLAccountSignInViewController *const weakSelf = self;

        CardCreatorConfiguration *const config = [self.businessLogic makeRegularCardCreationConfiguration];
        config.completionHandler = ^(NSString *const username, NSString *const PIN, BOOL const userInitiated) {
          if (userInitiated) {
            // Dismiss CardCreator & SignInVC when user finishes Credential Review
            [weakSelf.presentingViewController dismissViewControllerAnimated:YES completion:nil];
          } else {
            weakSelf.usernameTextField.text = username;
            weakSelf.PINTextField.text = PIN;
            [weakSelf updateLoginLogoutCellAppearance];
            weakSelf.businessLogic.isLoggingInAfterSignUp = YES;
            [weakSelf.businessLogic logIn];
          }
        };
        
        UINavigationController *const navigationController =
          [CardCreator initialNavigationControllerWithConfiguration:config];
        navigationController.navigationBar.topItem.leftBarButtonItem =
          [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                           style:UIBarButtonItemStylePlain
                                          target:self
                                          action:@selector(didSelectCancelForSignUp)];
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:navigationController animated:YES completion:nil];
      }
      else // does not support card creator
      {
        if (self.currentAccount.details.signUpUrl == nil) {
          // this situation should be impossible, but let's log it if it happens
          [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeNilSignUpURL
                                    summary:@"SignUp Error in modal: nil signUp URL"
                                    message:nil
                                   metadata:nil];
          return;
        }

        RemoteHTMLViewController *webVC =
        [[RemoteHTMLViewController alloc]
         initWithURL:self.currentAccount.details.signUpUrl
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
  }
}

#pragma mark UITableViewDataSource

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
                                           withOffset:marginPadding];
        [self.usernameTextField autoConstrainAttribute:ALAttributeBottom toAttribute:ALAttributeMarginBottom
                                               ofView:[self.usernameTextField superview]
                                           withOffset:-marginPadding];

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
                                           withOffset:marginPadding];
        [self.PINTextField autoConstrainAttribute:ALAttributeBottom toAttribute:ALAttributeMarginBottom
                                               ofView:[self.PINTextField superview]
                                           withOffset:-marginPadding];
      }
      return cell;
    }
    case CellKindLogInSignOut: {
      self.logInSignOutCell.textLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
      [self updateLoginLogoutCellAppearance];
      return self.logInSignOutCell;
    }
    case CellKindRegistration: {
      return [self createRegistrationCell];
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
  [regTitle autoConstrainAttribute:ALAttributeTop toAttribute:ALAttributeMarginTop ofView:[regTitle superview] withOffset:marginPadding];
  [regTitle autoConstrainAttribute:ALAttributeBottom toAttribute:ALAttributeMarginBottom ofView:[regTitle superview] withOffset:-marginPadding];
  [regButton autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:regTitle withOffset:8.0 relation:NSLayoutRelationGreaterThanOrEqual];
  [regButton autoPinEdgesToSuperviewMarginsExcludingEdge:ALEdgeLeft];
  [regButton setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

  UITableViewCell *cell = [[UITableViewCell alloc] init];
  [cell.contentView addSubview:containerView];
  containerView.preservesSuperviewLayoutMargins = YES;
  [containerView autoPinEdgesToSuperviewEdges];
  return cell;
}

- (NSInteger)numberOfSectionsInTableView:(__attribute__((unused)) UITableView *)tableView
{
  return self.tableData.count;
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
  if (section == SectionCredentials && [self.businessLogic shouldShowEULALink]) {
    UIView *container = [[UIView alloc] init];
    container.preservesSuperviewLayoutMargins = YES;
    UILabel *footerLabel = [[UILabel alloc] init];
    footerLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleCaption1];
    footerLabel.textColor = [UIColor lightGrayColor];
    footerLabel.numberOfLines = 0;
    footerLabel.userInteractionEnabled = YES;

    NSDictionary *linkAttributes = @{ NSForegroundColorAttributeName :
                                        [UIColor colorWithRed:0.05 green:0.4 blue:0.65 alpha:1.0],
                                      NSUnderlineStyleAttributeName :
                                        @(NSUnderlineStyleSingle) };
    NSMutableAttributedString *eulaString = [[NSMutableAttributedString alloc]
                                             initWithString:NSLocalizedString(@"SigningInAgree", nil) attributes:linkAttributes];
    footerLabel.attributedText = eulaString;
    [footerLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showEULA)]];

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

#pragma mark - NYPLSettingsAccountUIDelegate

- (NSString *)username
{
    return self.usernameTextField.text;
}

- (NSString *)pin
{
    return self.PINTextField.text;
}

#pragma mark - Class Methods

+ (void)
requestCredentialsUsingExistingBarcode:(BOOL const)useExistingBarcode
authorizeImmediately:(BOOL)authorizeImmediately
completionHandler:(void (^)(void))handler
{
  dispatch_async(dispatch_get_main_queue(), ^{
    NYPLAccountSignInViewController *signInVC = [[self alloc] init];
    [signInVC presentUsingExistingBarcode:useExistingBarcode
                     authorizeImmediately:authorizeImmediately
                        completionHandler:handler];
  });
}

+ (void)requestCredentialsUsingExistingBarcode:(BOOL)useExistingBarcode
                             completionHandler:(void (^)(void))handler
{
  [self requestCredentialsUsingExistingBarcode:useExistingBarcode
                          authorizeImmediately:NO
                             completionHandler:handler];
}

+ (void)authorizeUsingExistingBarcodeAndPinWithCompletionHandler:(void (^)(void))handler
{
  [self requestCredentialsUsingExistingBarcode:YES
                          authorizeImmediately:YES
                             completionHandler:handler];
}

#pragma mark -

/**
 * Presents itself to begin the login process.
 *
 * @param useExistingBarcode Should the screen be filled with the barcode when available?
 * @param authorizeImmediately Should the authentication process begin automatically after presenting? For Oauth2 and SAML it would mean opening a webview.
 * @param completionHandler Called upon successful authentication
 */
- (void)presentUsingExistingBarcode:(BOOL const)useExistingBarcode
               authorizeImmediately:(BOOL)authorizeImmediately
                  completionHandler:(void (^)(void))handler
{
  self.businessLogic.completionHandler = handler;

  // Tell the VC to create its text fields so we can set their properties.
  [self view];

  if (self.businessLogic.userAccount.authDefinition.isSaml) {
    if (!useExistingBarcode) {
      // if current authentication is SAML and we don't want to use current credentials, we need to force log in process
      // this is for the case when we were logged in, but IDP expired our session
      // and if this happens, we want the user to pick the idp to begin reauthentication
      self.businessLogic.ignoreSignedInState = true;
      self.businessLogic.selectedAuthentication = nil;
    }
  } else {
    if(useExistingBarcode) {
      NSString *const barcode = self.businessLogic.userAccount.barcode;
      if(!barcode) {
        @throw NSInvalidArgumentException;
      }
      self.usernameTextField.text = barcode;
    } else {
      self.usernameTextField.text = @"";
    }
  }

  self.PINTextField.text = @"";

  UIBarButtonItem *const cancelBarButtonItem =
  [[UIBarButtonItem alloc]
   initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
   target:self
   action:@selector(didSelectCancel)];

  self.navigationItem.leftBarButtonItem = cancelBarButtonItem;
  UINavigationController *const navVC = [[UINavigationController alloc]
                                         initWithRootViewController:self];
  navVC.modalPresentationStyle = UIModalPresentationFormSheet;

  [NYPLPresentationUtils safelyPresent:navVC animated:YES completion:nil];

  if (authorizeImmediately && self.businessLogic.userAccount.hasBarcodeAndPIN) {
    self.PINTextField.text = self.businessLogic.userAccount.PIN;
    [self.businessLogic logIn];
  } else if (self.businessLogic.userAccount.authDefinition.isOauth) {
    if (authorizeImmediately) {
      [self.businessLogic logIn];
    }
  } else if (self.businessLogic.userAccount.authDefinition.isSaml) {
    // there's no extra logic to do for SAML
    // this exists as we don't want the textfield to become responder
  } else {
    if(useExistingBarcode) {
      [self.PINTextField becomeFirstResponder];
    } else {
      [self.usernameTextField becomeFirstResponder];
    }
  }
}

- (void)textFieldsDidChange
{
  [self updateLoginLogoutCellAppearance];
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

      UIAlertAction *settingsAction = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"Settings", nil)
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action) {
        if (action) {
          [UIApplication.sharedApplication
           openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]
           options:@{}
           completionHandler:nil];
        }
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
    if(self.businessLogic.isSignedIn) {
      self.usernameTextField.text = self.businessLogic.userAccount.barcode;
      self.usernameTextField.enabled = NO;
      self.usernameTextField.textColor = [UIColor grayColor];
      self.PINTextField.text = self.businessLogic.userAccount.PIN;
      self.PINTextField.textColor = [UIColor grayColor];
    } else {
      self.usernameTextField.text = nil;
      self.usernameTextField.enabled = YES;
      self.usernameTextField.textColor = [UIColor defaultLabelColor];
      self.PINTextField.text = nil;
      self.PINTextField.textColor = [UIColor defaultLabelColor];
    }
    
    [self setupTableData];
    [self updateLoginLogoutCellAppearance];
  }];
}

- (void)showEULA
{
  UIViewController *eulaViewController = [[NYPLSettingsEULAViewController alloc] initWithAccount:self.currentAccount];
  UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:eulaViewController];
  [self.navigationController presentViewController:navVC animated:YES completion:nil];
}

- (void)updateLoginLogoutCellAppearance
{
  if (self.businessLogic.isCurrentlySigningIn) {
    return;
  }
  if(self.businessLogic.isSignedIn) {
    self.logInSignOutCell.textLabel.text = NSLocalizedString(@"SignOut", @"Title for sign out action");
    self.logInSignOutCell.textLabel.textAlignment = NSTextAlignmentCenter;
    self.logInSignOutCell.textLabel.textColor = [NYPLConfiguration mainColor];
    self.logInSignOutCell.userInteractionEnabled = YES;
  } else {
    self.logInSignOutCell.textLabel.text = NSLocalizedString(@"LogIn", nil);
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

- (void)businessLogicWillSignIn:(NYPLSignInBusinessLogic *)businessLogic
{
  if (!businessLogic.selectedAuthentication.isOauth
      && !businessLogic.selectedAuthentication.isSaml) {
    [self.usernameTextField resignFirstResponder];
    [self.PINTextField resignFirstResponder];
    [self setActivityTitleWithText:NSLocalizedString(@"Verifying", nil)];
  }
}

- (void)displayErrorMessage:(NSString *)errorMessage {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = errorMessage;
    [label sizeToFit];
    label.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
    [self.view addSubview:label];
}

- (void)setActivityTitleWithText:(NSString *)text
{
  // since we are adding a subview to self.logInSignOutCell.contentView, there
  // is no point in continuing if for some reason logInSignOutCell is nil.
  if (self.logInSignOutCell.contentView == nil) {
    return;
  }

  // check if we already added the activity view
  if ([self.logInSignOutCell.contentView viewWithTag:sLinearViewTag] != nil) {
    return;
  }
  
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
  linearView.tag = sLinearViewTag;
  linearView.contentVerticalAlignment = NYPLLinearViewContentVerticalAlignmentMiddle;
  linearView.padding = 5.0;
  [linearView addSubview:activityIndicatorView];
  [linearView addSubview:titleLabel];
  [linearView addSubview:rightPaddingView];
  [linearView sizeToFit];
  [linearView autoSetDimensionsToSize:CGSizeMake(linearView.frame.size.width, linearView.frame.size.height)];
  
  self.logInSignOutCell.textLabel.text = nil;
  [self.logInSignOutCell.contentView addSubview:linearView];
  [linearView autoCenterInSuperview];
}

- (void)removeActivityTitle {
  UIView *view = [self.logInSignOutCell.contentView viewWithTag:sLinearViewTag];
  [view removeFromSuperview];
  [self updateLoginLogoutCellAppearance];
}

- (void)alertUserOfValidationError:(NSError * const)error
                    problemDocData:(NSData * const)data
                          response:(NSURLResponse * const)response
                    loggingContext:(NSDictionary<NSString*, id> *)loggingContext
{
  [self removeActivityTitle];

  if (error.code == NSURLErrorCancelled) {
    // We cancelled the request when asked to answer the server's challenge
    // a second time because we don't have valid credentials.
    self.PINTextField.text = @"";
    [self textFieldsDidChange];
    [self.PINTextField becomeFirstResponder];
  }

  UIAlertController *alert = nil;

  // rely on problem document if available
  NYPLProblemDocument *problemDocument = nil;
  NSError *problemDocumentParseError = nil;
  if (response.isProblemDocument) {
    problemDocument = [NYPLProblemDocument fromData:data
                                              error:&problemDocumentParseError];
    if (problemDocumentParseError == nil && problemDocument != nil) {
      alert = [NYPLAlertUtils alertWithTitle:problemDocument.title
                                     message:problemDocument.detail];
    }
  }

  // error logging
  if (problemDocumentParseError != nil) {
    [NYPLErrorLogger logProblemDocumentParseError:problemDocumentParseError
                              problemDocumentData:data
                                              url:nil
                                          summary:@"Sign-in validation: Problem Doc parse error"
                                         metadata:loggingContext];
  } else {
    [NYPLErrorLogger logLoginError:error
                           library:self.businessLogic.libraryAccount
                          response:response
                   problemDocument:problemDocument
                          metadata:loggingContext];
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

/**
 @note This method is not doing any logging in case `success` is false.

 @param success Whether Adobe DRM authorization was successful or not.
 @param error If errorMessage is absent, this will be used to derive a message
 to present to the user.
 @param errorMessage Will be presented to the user and will be used as a
 localization key to attempt to localize it.
 */
- (void)finalizeSignInForDRMAuthorization:(BOOL)success
                                    error:(NSError *)error
                             errorMessage:(NSString*)errorMessage
{
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [self removeActivityTitle];

    [self.businessLogic
     finalizeSignInForDRMAuthorization:success
     error:error
     errorMessage:errorMessage
     withBarcode:self.usernameTextField.text
     pin:self.PINTextField.text
     cookies:self.cookies];
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
