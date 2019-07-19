@import LocalAuthentication;
@import NYPLCardCreator;

#import "SimplyE-Swift.h"

#import "NYPLAccount.h"
#import "NYPLAppDelegate.h"
#import "NYPLBarcodeScanningViewController.h"
#import "NYPLBasicAuth.h"
#import "NYPLBookCoverRegistry.h"
#import "NYPLBookRegistry.h"
#import "NYPLConfiguration.h"
#import "NYPLLinearView.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLReachability.h"

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

@interface NYPLAccountSignInViewController () <NSURLSessionDelegate, UITextFieldDelegate, UIAlertViewDelegate>

@property (nonatomic) Account *currentAccount;
@property (nonatomic) BOOL isLoggingInAfterSignUp;
@property (nonatomic) BOOL loggingInAfterBarcodeScan;
@property (nonatomic) BOOL isCurrentlySigningIn;
@property (nonatomic) UITextField *usernameTextField;
@property (nonatomic) UIButton *barcodeScanButton;
@property (nonatomic, copy) void (^completionHandler)(void);
@property (nonatomic) BOOL hiddenPIN;
@property (nonatomic) UITableViewCell *logInSignOutCell;
@property (nonatomic) UITextField *PINTextField;
@property (nonatomic) NSURLSession *session;
@property (nonatomic) UIButton *PINShowHideButton;
@property (nonatomic) bool rotated;
@property (nonatomic) NSArray *tableData;

@end

@implementation NYPLAccountSignInViewController

CGFloat const marginPadding = 2.0;

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
  
  configuration.timeoutIntervalForResource = 15.0;
  
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
  self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;

  self.currentAccount = [AccountsManager shared].currentAccount;
  
  self.usernameTextField = [[UITextField alloc] initWithFrame:CGRectZero];
  self.usernameTextField.delegate = self;
  self.usernameTextField.placeholder = NSLocalizedString(@"BarcodeOrUsername", nil);

  switch (self.currentAccount.details.patronIDKeyboard) {
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

  switch (self.currentAccount.details.pinKeyboard) {
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

  self.barcodeScanButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.barcodeScanButton setImage:[UIImage imageNamed:@"CameraIcon"] forState:UIControlStateNormal];
  [self.barcodeScanButton addTarget:self action:@selector(scanLibraryCard)
                   forControlEvents:UIControlEventTouchUpInside];

  self.logInSignOutCell = [[UITableViewCell alloc]
                           initWithStyle:UITableViewCellStyleDefault
                           reuseIdentifier:nil];

  [self setupTableData];
}

- (void)setupTableData
{
  NSArray *section0;
  if (self.currentAccount.details.pinKeyboard != LoginKeyboardNone) {
    section0 = @[@(CellKindBarcode),
                 @(CellKindPIN),
                 @(CellKindLogInSignOut)];
  } else {
    //Server expects a blank string. Passes local textfield validation.
    self.PINTextField.text = @"";
    section0 = @[@(CellKindBarcode),
                 @(CellKindLogInSignOut)];
  }
  NSArray *section1;
  if ([self registrationIsPossible]) {
    section1 = @[@(CellKindRegistration)];
  } else {
    section1 = @[];
  }
  self.tableData = @[section0, section1];
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

#if defined(FEATURE_DRM_CONNECTOR)
- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  if (![[NYPLADEPT sharedInstance] isUserAuthorized:[[NYPLAccount sharedAccount] userID] withDevice:[[NYPLAccount sharedAccount] deviceID]]) {
    if ([[NYPLAccount sharedAccount] hasBarcodeAndPIN] && !self.isCurrentlySigningIn) {
      self.usernameTextField.text = [NYPLAccount sharedAccount].barcode;
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
  NSArray *sectionArray = (NSArray *)self.tableData[indexPath.section];
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
      [self logIn];
      break;
    case CellKindRegistration: {
      [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
      
      if (self.currentAccount.details.supportsCardCreator) {
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
        
        RemoteHTMLViewController *webViewController = [[RemoteHTMLViewController alloc] initWithURL:[[NSURL alloc] initWithString:self.currentAccount.details.cardCreatorUrl] title:@"eCard" failureMessage:NSLocalizedString(@"SettingsConnectionFailureMessage", nil)];
        
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
                                           withOffset:marginPadding];
        [self.usernameTextField autoConstrainAttribute:ALAttributeBottom toAttribute:ALAttributeMarginBottom
                                               ofView:[self.usernameTextField superview]
                                           withOffset:-marginPadding];

        if (self.currentAccount.details.supportsBarcodeScanner) {
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

- (BOOL)registrationIsPossible
{
  return ([NYPLConfiguration cardCreationEnabled] &&
          ([[AccountsManager sharedInstance] currentAccount].details.supportsCardCreator || [[AccountsManager sharedInstance] currentAccount].details.cardCreatorUrl) &&
          ![[NYPLAccount sharedAccount] hasBarcodeAndPIN]);
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
  if (section == SectionCredentials && [self.currentAccount.details getLicenseURL:URLTypeEula]) {
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
     self.currentAccount.details.patronIDKeyboard != LoginKeyboardEmail) {
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
    bool alphanumericPin = self.currentAccount.details.pinKeyboard != LoginKeyboardNumeric;
    bool containsNonNumericChar = [string stringByTrimmingCharactersInSet:charSet].length > 0;
    bool abovePinCharLimit = [textField.text stringByReplacingCharactersInRange:range withString:string].length > self.currentAccount.details.authPasscodeLength;
    
    // PIN's support numeric or alphanumeric.
    if (!alphanumericPin && containsNonNumericChar) {
      return NO;
    }
    // PIN's character limit. Zero is unlimited.
    if (self.currentAccount.details.authPasscodeLength == 0) {
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
completionHandler:(void (^)(void))handler
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
    accountViewController.usernameTextField.text = barcode;
  } else {
    accountViewController.usernameTextField.text = @"";
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
      [accountViewController.usernameTextField becomeFirstResponder];
    }
  }
}

+ (void)requestCredentialsUsingExistingBarcode:(BOOL)useExistingBarcode
                             completionHandler:(void (^)(void))handler
{
  [self requestCredentialsUsingExistingBarcode:useExistingBarcode authorizeImmediately:NO completionHandler:handler];
}

+ (void)authorizeUsingExistingBarcodeAndPinWithCompletionHandler:(void (^)(void))handler
{
  [self requestCredentialsUsingExistingBarcode:YES authorizeImmediately:YES completionHandler:handler];
}

#pragma mark -

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
      self.usernameTextField.text = [NYPLAccount sharedAccount].barcode;
      self.usernameTextField.enabled = NO;
      self.usernameTextField.textColor = [UIColor grayColor];
      self.PINTextField.text = [NYPLAccount sharedAccount].PIN;
      self.PINTextField.textColor = [UIColor grayColor];
    } else {
      self.usernameTextField.text = nil;
      self.usernameTextField.enabled = YES;
      self.usernameTextField.textColor = [UIColor blackColor];
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
    BOOL const barcodeHasText = [self.usernameTextField.text
                                 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length;
    BOOL const pinHasText = [self.PINTextField.text
                             stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length;
    BOOL const pinIsNotRequired = self.currentAccount.details.pinKeyboard == LoginKeyboardNone;
    if((barcodeHasText && pinHasText) || (barcodeHasText && pinIsNotRequired)) {
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
  assert(self.usernameTextField.text.length > 0);
  assert(self.PINTextField.text.length > 0 || [self.PINTextField.text isEqualToString:@""]);

  [self.usernameTextField resignFirstResponder];
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
  titleLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
  [titleLabel sizeToFit];
  
  // This view is used to keep the title label centered as in Apple's Settings application.
  UIView *const rightPaddingView = [[UIView alloc] initWithFrame:activityIndicatorView.bounds];

  NSInteger linearViewTag = 1;
  
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
  UIView *view = [self.logInSignOutCell.contentView viewWithTag:1];
  [view removeFromSuperview];
}

- (void)validateCredentials
{
  NSMutableURLRequest *const request =
    [NSMutableURLRequest requestWithURL:[NSURL URLWithString:
      [[[[AccountsManager sharedInstance] currentAccount] details] userProfileUrl]]];
  
  request.timeoutInterval = 20.0;
  
  self.isCurrentlySigningIn = YES;
  NSURLSessionDataTask *const task =
    [self.session
     dataTaskWithRequest:request
     completionHandler:^(__unused NSData *data,
                         NSURLResponse *const response,
                         NSError *const error) {
       
       self.isCurrentlySigningIn = NO;

       NSInteger const statusCode = ((NSHTTPURLResponse *) response).statusCode;
       
       if (statusCode == 200) {
#if defined(FEATURE_DRM_CONNECTOR)
         NSError *pDocError = nil;
         ProtocolDocument *pDoc = [ProtocolDocument fromData:data error:&pDocError];
         if (!pDoc) {
           [NYPLBugsnagLogs reportProtocolDocumentErrorWithError:pDocError];
           [self authorizationAttemptDidFinish:NO error:nil];
           return;
         } else {
           if (pDoc.authorizationIdentifier) {
             [[NYPLAccount sharedAccount] setAuthorizationIdentifier:pDoc.authorizationIdentifier];
           } else {
             NYPLLOG(@"Authorization ID (Barcode String) was nil.");
           }
           if (pDoc.drm.count > 0 && pDoc.drm[0].clientToken && pDoc.drm[0].vendor) {
             [[NYPLAccount sharedAccount] setLicensor:pDoc.drm[0].licensor];
           } else {
             NYPLLOG(@"Login Failed: No Licensor Token received or parsed from OPDS Loans feed");
             [self authorizationAttemptDidFinish:NO error:nil];
             return;
           }
           
           NSMutableArray *licensorItems = [[pDoc.drm[0].clientToken stringByReplacingOccurrencesOfString:@"\n" withString:@""] componentsSeparatedByString:@"|"].mutableCopy;
           NSString *tokenPassword = [licensorItems lastObject];
           [licensorItems removeLastObject];
           NSString *tokenUsername = [licensorItems componentsJoinedByString:@"|"];
           
           NYPLLOG(@"***DRM Auth/Activation Attempt***");
           NYPLLOG_F(@"\nLicensor: %@\n",pDoc.drm[0].licensor);
           NYPLLOG_F(@"Token Username: %@\n",tokenUsername);
           NYPLLOG_F(@"Token Password: %@\n",tokenPassword);
           
           [[NYPLADEPT sharedInstance]
            authorizeWithVendorID:[[NYPLAccount sharedAccount] licensor][@"vendor"]
            username:tokenUsername
            password:tokenPassword
            completion:^(BOOL success, NSError *error, NSString *deviceID, NSString *userID) {

              [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [NSObject cancelPreviousPerformRequestsWithTarget:self];
              }];

              NYPLLOG_F(@"Activation Success: %@\n", success ? @"Yes" : @"No");
              NYPLLOG_F(@"Error: %@\n",error.localizedDescription);
              NYPLLOG_F(@"UserID: %@\n",userID);
              NYPLLOG_F(@"DeviceID: %@\n",deviceID);
              NYPLLOG(@"***DRM Auth/Activation Completion***");
              
              if (success) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                  [[NYPLAccount sharedAccount] setUserID:userID];
                  [[NYPLAccount sharedAccount] setDeviceID:deviceID];
                }];
              }
              
              [self authorizationAttemptDidFinish:success error:error];
            }];

           [self performSelector:@selector(dismissAfterUnexpectedDRMDelay) withObject:self afterDelay:25];
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
         return;
       }
       [self showLoginAlertWithError:error];
       
     }];
  
  [task resume];
}

- (void)dismissAfterUnexpectedDRMDelay
{
  __weak NYPLAccountSignInViewController *const weakSelf = self;

  NSString *title = NSLocalizedString(@"Sign In Error", nil);
  NSString *message = NSLocalizedString(@"The DRM Library is taking longer than expected. Please wait and try again later.\n\nIf the problem persists, try to sign out and back in again from the Library Settings menu.", nil);

  UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction * _Nonnull __unused action) {
                                            [weakSelf dismissViewControllerAnimated:YES completion:nil];
                                          }]];
  [NYPLAlertUtils presentFromViewControllerOrNilWithAlertController:alert viewController:nil animated:YES completion:nil];
}

- (void)showLoginAlertWithError:(NSError *)error
{
  [[NYPLRootTabBarController sharedController] safelyPresentViewController:
   [NYPLAlertUtils alertWithTitle:@"SettingsAccountViewControllerLoginFailed" error:error]
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
      [[NYPLAccount sharedAccount] setBarcode:self.usernameTextField.text
                                          PIN:self.PINTextField.text];
      if (!self.isLoggingInAfterSignUp) {
        [self dismissViewControllerAnimated:YES completion:nil];
      }
      void (^handler)(void) = self.completionHandler;
      self.completionHandler = nil;
      if(handler) handler();
      [[NYPLBookRegistry sharedRegistry] syncWithCompletionHandler:^(BOOL __unused success) {
        if (success) {
          [[NYPLBookRegistry sharedRegistry] save];
        }
      }];

    } else {
      [[NYPLAccount sharedAccount] removeAll];
      [self accountDidChange];
      [[NSNotificationCenter defaultCenter] postNotificationName:NSNotification.NYPLSyncEnded object:nil];
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
