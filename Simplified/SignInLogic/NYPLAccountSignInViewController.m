@import LocalAuthentication;
@import NYPLCardCreator;
@import CoreLocation;

#import <PureLayout/PureLayout.h>

#import "SimplyE-Swift.h"

#import "NYPLAccountSignInViewController.h"
#import "NYPLAppDelegate.h"
#import "NYPLBookCoverRegistry.h"
#import "NYPLBookRegistry.h"
#import "NYPLConfiguration.h"
#import "NYPLLinearView.h"
#import "NYPLOPDSFeed.h"
#import "NYPLReachability.h"
#import "NYPLRootTabBarController.h"
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
  CellKindLogIn,
  CellKindRegistration
};

typedef NS_ENUM(NSInteger, Section) {
  SectionCredentials = 0,
  SectionRegistration = 1
};

// Note that this class does not actually have anything to do with logging out.
// The compliance with the NYPLSignInOutBusinessLogicUIDelegate protocol
// is merely so that we can use this VC with the NYPLSignInBusinessLogic
// class which is handling signing out too.
@interface NYPLAccountSignInViewController () <NYPLSignInOutBusinessLogicUIDelegate>

// view state
@property (nonatomic) BOOL loggingInAfterBarcodeScan;
@property (nonatomic) BOOL hiddenPIN;

// UI
@property (nonatomic) UIButton *barcodeScanButton;
@property (nonatomic) UITableViewCell *logInCell;
@property (nonatomic) UIButton *PINShowHideButton;
@property (nonatomic) NSArray *tableData;

// account state
@property NYPLUserAccountFrontEndValidation *frontEndValidator;
@property (nonatomic) NYPLSignInBusinessLogic *businessLogic;

@end

@implementation NYPLAccountSignInViewController

@synthesize usernameTextField;
@synthesize PINTextField;

CGFloat const marginPadding = 2.0;

#pragma mark - NYPLSignInOutBusinessLogicUIDelegate properties

- (NSString *)context
{
  return @"SignIn-modal";
}

- (NSString *)username
{
  return self.usernameTextField.text;
}

- (NSString *)pin
{
  return self.PINTextField.text;
}

#pragma mark - NSObject

- (instancetype)init
{
  self = [super initWithStyle:UITableViewStyleGrouped];
  if(!self) return nil;

  self.businessLogic = [[NYPLSignInBusinessLogic alloc]
                        initWithLibraryAccountID:AccountsManager.shared.currentAccountId
                        libraryAccountsProvider:AccountsManager.shared
                        urlSettingsProvider: NYPLSettings.shared
                        bookRegistry:[NYPLBookRegistry sharedRegistry]
                        bookDownloadsCenter:[NYPLMyBooksDownloadCenter sharedDownloadCenter]
                        userAccountProvider:[NYPLUserAccount class]
                        uiDelegate:self
                        drmAuthorizer:
#if FEATURE_DRM_CONNECTOR
                        [NYPLADEPT sharedInstance]
#else
                        nil
#endif
                        ];

  self.title = NSLocalizedString(@"Sign In", nil);

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
  
  self.frontEndValidator = [[NYPLUserAccountFrontEndValidation alloc]
                            initWithAccount:self.businessLogic.libraryAccount
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

  self.logInCell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleDefault
                    reuseIdentifier:nil];

  [self setupTableData];
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
    [self updateInputUIForcingEditability:self.forceEditability];
    [self updateShowHidePINState];
  }
}

#if defined(FEATURE_DRM_CONNECTOR)
- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [self.businessLogic logInIfUserAuthorized];
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
    case CellKindLogIn:
      [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
      [self.businessLogic logIn];
      break;
    case CellKindRegistration: {
      [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
      UINavigationController *navController = [self.businessLogic makeCardCreatorIfPossible];
      if (navController != nil) {
        navController.navigationBar.topItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(didSelectCancelForSignUp)];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:navController animated:YES completion:nil];
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
    case CellKindLogIn: {
      self.logInCell.textLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
      [self updateLoginCellAppearance];
      return self.logInCell;
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
  regTitle.text = NSLocalizedString(@"Don't have a library card?", @"Title for registration. Asking the user if they already have a library card.");
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

#pragma mark - Modal presentation

+ (void)requestCredentialsWithCompletion:(void (^)(void))completion
{
  [NYPLMainThreadRun asyncIfNeeded:^{
    NYPLAccountSignInViewController *signInVC = [[self alloc] init];
    [signInVC presentIfNeededUsingExistingCredentials:NO
                                    completionHandler:completion];
  }];
}

/**
 * Presents itself to begin the login process.
 *
 * @param useExistingCredentials Should the screen be filled with the barcode when available?
 * @param completionHandler Called upon successful authentication
 */
- (void)presentIfNeededUsingExistingCredentials:(BOOL const)useExistingCredentials
                              completionHandler:(void (^)(void))completionHandler
{
  // Tell the VC to create its text fields so we can set their properties.
  [self view];

  BOOL shouldPresentVC = [self.businessLogic
                          refreshAuthIfNeededUsingExistingCredentials:useExistingCredentials
                          completion:completionHandler];

  if (shouldPresentVC) {
    [self presentAsModal];
  }
}

- (void)presentAsModal
{
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
}

#pragma mark - Table view set up helpers

- (NSArray *)cellsForAuthMethod:(AccountDetailsAuthentication *)authenticationMethod {
  NSArray *authCells;

  if (authenticationMethod.isOauth) {
    // Oauth just needs the login button since it will open Safari for
    // actual authentication
    authCells = @[@(CellKindLogIn)];
  } else if (authenticationMethod.isSaml) {
    // make a list of all possible IDPs to login via SAML
    NSMutableArray *multipleCells = @[].mutableCopy;
    for (OPDS2SamlIDP *idp in authenticationMethod.samlIdps) {
      NYPLSamlIdpCellType *idpCell = [[NYPLSamlIdpCellType alloc] initWithIdp:idp];
      [multipleCells addObject:idpCell];
    }
    authCells = multipleCells;
  } else if (authenticationMethod.pinKeyboard != LoginKeyboardNone) {
    // if authentication method has an information about pin keyboard, the login method is requires a pin
    authCells = @[@(CellKindBarcode), @(CellKindPIN), @(CellKindLogIn)];
  } else {
    // if all other cases failed, it means that server expects just a barcode, with a blank pin
    self.PINTextField.text = @"";
    authCells = @[@(CellKindBarcode), @(CellKindLogIn)];
  }

  return authCells;
}

- (NSArray *)accountInfoSection {
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

#pragma mark - PIN Show/Hide

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

- (void)updateShowHidePINState
{
  self.PINTextField.rightView.hidden = YES;

  LAContext *const context = [[LAContext alloc] init];
  if([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:NULL]) {
    self.PINTextField.rightView.hidden = NO;
  }
}

#pragma mark -

- (void)scanLibraryCard
{
#ifdef OPENEBOOKS
  __auto_type auth = self.businessLogic.selectedAuthentication;
  [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeAppLogicInconsistency
                            summary:@"Barcode button was displayed"
                            message:nil
                           metadata:@{
                             @"Supports barcode display": @(auth.supportsBarcodeDisplay) ?: @"N/A",
                             @"Supports barcode scanner": @(auth.supportsBarcodeScanner) ?: @"N/A",
                             @"Context": @"Sign-in modal",
                           }];
#else
  [NYPLBarcode presentScannerWithCompletion:^(NSString * _Nullable resultString) {
    if (resultString) {
      self.usernameTextField.text = resultString;
      [self.PINTextField becomeFirstResponder];
      self.loggingInAfterBarcodeScan = YES;
    }
  }];
#endif
}

- (void)didSelectCancel
{
  [self.navigationController.presentingViewController
   dismissViewControllerAnimated:YES
   completion:nil];
}

- (void)didSelectCancelForSignUp
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showEULA
{
  UIViewController *eulaViewController = [[NYPLSettingsEULAViewController alloc] initWithAccount:self.businessLogic.libraryAccount];
  UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:eulaViewController];
  [self.navigationController presentViewController:navVC animated:YES completion:nil];
}

#pragma mark - UI update

- (void)accountDidChange
{
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [self updateInputUIForcingEditability:NO];
  }];
}

- (void)updateInputUIForcingEditability:(BOOL)forceEditability
{
  if(self.businessLogic.isSignedIn) {
    self.usernameTextField.text = self.businessLogic.userAccount.barcode;
    self.usernameTextField.enabled = forceEditability;
    self.PINTextField.text = self.businessLogic.userAccount.PIN;
    self.PINTextField.enabled = forceEditability;
    if (forceEditability) {
      self.usernameTextField.textColor = [UIColor blackColor];
      self.PINTextField.textColor = [UIColor blackColor];
    } else {
      self.usernameTextField.textColor = [UIColor grayColor];
      self.PINTextField.textColor = [UIColor grayColor];
    }
  } else {
    self.usernameTextField.text = nil;
    self.usernameTextField.enabled = YES;
    self.usernameTextField.textColor = [UIColor defaultLabelColor];
    self.PINTextField.text = nil;
    self.PINTextField.enabled = YES;
    self.PINTextField.textColor = [UIColor defaultLabelColor];
  }

  [self setupTableData];
  [self updateLoginCellAppearance];
}

- (void)updateLoginCellAppearance
{
  if (self.businessLogic.isCurrentlySigningIn) {
    return;
  }

  if (self.businessLogic.isSignedIn && !self.forceEditability) {
    return;
  }

  self.logInCell.textLabel.text = NSLocalizedString(@"LogIn", nil);
  BOOL const barcodeHasText = [self.usernameTextField.text
                               stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length;
  BOOL const pinHasText = [self.PINTextField.text
                           stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length;
  BOOL const pinIsNotRequired = self.businessLogic.selectedAuthentication.pinKeyboard == LoginKeyboardNone;
  BOOL const oauthLogin = self.businessLogic.selectedAuthentication.isOauth;

  if ((barcodeHasText && (pinHasText || pinIsNotRequired)) || oauthLogin) {
    self.logInCell.userInteractionEnabled = YES;
    self.logInCell.textLabel.textColor = [NYPLConfiguration mainColor];
  } else {
    self.logInCell.userInteractionEnabled = NO;
    if (@available(iOS 13.0, *)) {
      self.logInCell.textLabel.textColor = [UIColor systemGray2Color];
    } else {
      self.logInCell.textLabel.textColor = [UIColor lightGrayColor];
    }
  }
}

- (void)displayErrorMessage:(NSString *)errorMessage
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = errorMessage;
    [label sizeToFit];
    label.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
    [self.view addSubview:label];
}

- (void)setActivityTitleWithText:(NSString *)text
{
  // since we are adding a subview to self.logInCell.contentView, there
  // is no point in continuing if for some reason logInCell is nil.
  if (self.logInCell.contentView == nil) {
    return;
  }

  // check if we already added the activity view
  if ([self.logInCell.contentView viewWithTag:sLinearViewTag] != nil) {
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
  
  self.logInCell.textLabel.text = nil;
  [self.logInCell.contentView addSubview:linearView];
  [linearView autoCenterInSuperview];
}

- (void)removeActivityTitle
{
  UIView *view = [self.logInCell.contentView viewWithTag:sLinearViewTag];
  [view removeFromSuperview];
  [self updateLoginCellAppearance];
}

#pragma mark - Text Input

- (void)textFieldsDidChange
{
  [self updateLoginCellAppearance];
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
                              CGPointMake(0, CGRectGetMaxY(self.logInCell.frame)))) {
        // We use an explicit animation block here because |setContentOffset:animated:| does not seem
        // to work at all.
        [UIView animateWithDuration:0.25 animations:^{
          [self.tableView setContentOffset:CGPointMake(0, -self.tableView.contentInset.top + 20)];
        }];
      }
    }
  }];
}

#pragma mark - UIApplication observer callbacks

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

#pragma mark - NYPLSignInBusinessLogicUIDelegate

- (void)businessLogicWillSignIn:(NYPLSignInBusinessLogic *)businessLogic
{
  if (!businessLogic.selectedAuthentication.isOauth
      && !businessLogic.selectedAuthentication.isSaml) {
    [self.usernameTextField resignFirstResponder];
    [self.PINTextField resignFirstResponder];
    [self setActivityTitleWithText:NSLocalizedString(@"Verifying", nil)];
  }
}

/**
 @note This method is not doing any logging in case `success` is false.

 @param success Whether Adobe DRM authorization was successful or not.
 @param error If errorMessage is absent, this will be used to derive a message
 to present to the user.
 @param errorMessage Will be presented to the user and will be used as a
 localization key to attempt to localize it.
 */
- (void)businessLogicDidCompleteSignIn:(NYPLSignInBusinessLogic *)businessLogic
{
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [self removeActivityTitle];
  }];
}

- (void)      businessLogic:(NYPLSignInBusinessLogic *)businessLogic
didEncounterValidationError:(NSError *)error
     userFriendlyErrorTitle:(NSString *)title
                 andMessage:(NSString *)serverMessage
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
  if (serverMessage != nil) {
    alert = [NYPLAlertUtils alertWithTitle:title
                                   message:serverMessage];
  } else {
    alert = [NYPLAlertUtils alertWithTitle:title
                                     error:error];
  }

  [NYPLPresentationUtils safelyPresent:alert animated:YES completion:nil];
}

- (void)   businessLogic:(NYPLSignInBusinessLogic *)logic
didEncounterSignOutError:(NSError *)error
      withHTTPStatusCode:(NSInteger)statusCode
{
}

- (void)businessLogicWillSignOut:(NYPLSignInBusinessLogic *)businessLogic
{
}

- (void)businessLogicDidFinishDeauthorizing:(NYPLSignInBusinessLogic *)businessLogic
{
}

@end
