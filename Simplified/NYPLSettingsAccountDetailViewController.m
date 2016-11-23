@import LocalAuthentication;
@import NYPLCardCreator;


#import "NYPLAccount.h"
#import "NYPLAlertController.h"
#import "NYPLBasicAuth.h"
#import "NYPLBookCoverRegistry.h"
#import "NYPLBookRegistry.h"
#import "NYPLConfiguration.h"
#import "NYPLLinearView.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLReachability.h"
#import "NYPLSettings.h"
#import "NYPLSettingsAccountDetailViewController.h"
#import "NYPLSettingsContentLicenseViewController.h"
#import "NYPLSettingsEULAViewController.h"
#import "NYPLSettingsPrivacyPolicyViewController.h"
#import "NYPLSettingsRegistrationViewController.h"
#import "NYPLRootTabBarController.h"
#import "UIView+NYPLViewAdditions.h"
#import "SimplyE-Swift.h"

@import CoreLocation;

#if defined(FEATURE_DRM_CONNECTOR)
#import <ADEPT/ADEPT.h>
#endif

typedef NS_ENUM(NSInteger, CellKind) {
  CellKindAccountHeader,
  CellKindBarcode,
  CellKindPIN,
  CellKindLogInSignOut,
  CellKindRegistration,
  CellKindEULA,
  CellKindSyncButton,
  CellKindAbout,
  CellKindPrivacyPolicy,
  CellKindContentLicense,
  CellKindContact
};

typedef NS_ENUM(NSInteger, Section) {
  SectionAccountHeader = 0,
  SectionBarcodePin = 1,
  SectionEULA = 2,
  SectionSyncOrLicenses = 3,
  SectionLicenses = 4,
};

static CellKind CellKindFromIndexPath(NSIndexPath *const indexPath)
{
  switch(indexPath.section) {
      
    case 0:
      switch(indexPath.row) {
        case 0:
          return CellKindAccountHeader;
        default:
          @throw NSInvalidArgumentException;
      }
      
    case 1:
      switch(indexPath.row) {
        case 0:
          return CellKindBarcode;
        case 1:
          return CellKindPIN;
        default:
          @throw NSInvalidArgumentException;
      }
      
    case 2:
      switch(indexPath.row) {
        case 0:
          return CellKindEULA;
        case 1:
          return CellKindLogInSignOut;
        case 2:
          return CellKindRegistration;
        default:
          @throw NSInvalidArgumentException;
      }
      
    case 3:
      if ([[NYPLSettings sharedSettings] annotationsURL]) {
        switch (indexPath.row) {
          case 0:
            return CellKindSyncButton;
          default:
            @throw NSInvalidArgumentException;
        }
      } else {
        switch (indexPath.row) {
          case 0:
            return CellKindAbout;
          case 1:
            return CellKindPrivacyPolicy;
          case 2:
            return CellKindContentLicense;
          case 3:
            return CellKindContact;
          default:
            @throw NSInvalidArgumentException;
        }
      }
      
    case 4:
      switch (indexPath.row) {
        case 0:
          return CellKindAbout;
        case 1:
          return CellKindPrivacyPolicy;
        case 2:
          return CellKindContentLicense;
        case 3:
          return CellKindContact;
        default:
          @throw NSInvalidArgumentException;
      }
      
    default:
      @throw NSInvalidArgumentException;
  }
}

@interface NYPLSettingsAccountDetailViewController () <NSURLSessionDelegate, UITextFieldDelegate>

@property (nonatomic) BOOL isLoggingInAfterSignUp;
@property (nonatomic) UITextField *barcodeTextField;
@property (nonatomic, copy) void (^completionHandler)();
@property (nonatomic) BOOL hiddenPIN;
@property (nonatomic) UITableViewCell *eulaCell;
@property (nonatomic) UITableViewCell *logInSignOutCell;
@property (nonatomic) UITextField *PINTextField;
@property (nonatomic) NSURLSession *session;
@property (nonatomic) UIButton *PINShowHideButton;
@property (nonatomic) NYPLUserAccountType account;

@end

NSString *const NYPLSettingsAccountsSignInFinishedNotification = @"NYPLSettingsAccountsSignInFinishedNotification";

@implementation NYPLSettingsAccountDetailViewController

#pragma mark NSObject


- (instancetype)initWithAccount:(NSInteger)account
{
  self.account = account;
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
   selector:@selector(willResignActive)
   name:UIApplicationWillResignActiveNotification
   object:nil];

  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(willEnterForeground)
   name:UIApplicationWillEnterForegroundNotification
   object:nil];
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(changedCurrentAccount)
   name:NYPLCurrentAccountDidChangeNotification
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
//  if (![[NYPLADEPT sharedInstance] deviceAuthorized]) {
//    if ([[NYPLAccount sharedAccount:self.account] hasBarcodeAndPIN]) {
//      self.barcodeTextField.text = [NYPLAccount sharedAccount:self.account].barcode;
//      self.PINTextField.text = [NYPLAccount sharedAccount:self.account].PIN;
//      [self logIn];
//    }
//  }
}
#endif

#pragma mark UITableViewDelegate

- (void)tableView:(__attribute__((unused)) UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *const)indexPath
{
  switch(CellKindFromIndexPath(indexPath)) {
    case CellKindAccountHeader:
      break;
    case CellKindBarcode:
      [self.barcodeTextField becomeFirstResponder];
      break;
    case CellKindPIN:
      [self.PINTextField becomeFirstResponder];
      break;
    case CellKindEULA: {
      UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
      Account *accountItem = [[[Accounts alloc] init] account:self.account];
      if ([[NYPLSettings sharedSettings] userAcceptedEULAForAccount:accountItem] == YES) {
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CheckboxOff"]];
        [[NYPLSettings sharedSettings] setUserAcceptedEULA:NO forAccount:accountItem];
      } else {
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CheckboxOn"]];
        [[NYPLSettings sharedSettings] setUserAcceptedEULA:YES forAccount:accountItem];
      }
      [self updateLoginLogoutCellAppearance];
      break;
    }
    case CellKindLogInSignOut:
      [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
      if([[NYPLAccount sharedAccount:self.account] hasBarcodeAndPIN]) {
        UIAlertController *const alertController =
          (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad
           ? [UIAlertController
              alertControllerWithTitle:NSLocalizedString(@"SignOut", nil)
              message:NSLocalizedString(@"SettingsAccountViewControllerLogoutMessage", nil)
              preferredStyle:UIAlertControllerStyleAlert]
           : [UIAlertController
              alertControllerWithTitle:
                NSLocalizedString(@"SettingsAccountViewControllerLogoutMessage", nil)
              message:nil
              preferredStyle:UIAlertControllerStyleActionSheet]);
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
        [self presentViewController:alertController animated:YES completion:nil];
      } else {
        [self logIn];
      }
      break;
    case CellKindRegistration: {
      [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
      __weak NYPLSettingsAccountDetailViewController *const weakSelf = self;
      CardCreatorConfiguration *const configuration =
        [[CardCreatorConfiguration alloc]
         initWithEndpointURL:[APIKeys cardCreatorEndpointURL]
         endpointUsername:[APIKeys cardCreatorUsername]
         endpointPassword:[APIKeys cardCreatorPassword]
         requestTimeoutInterval:20.0
         completionHandler:^(NSString *const username, NSString *const PIN, BOOL const userInitiated) {
           if (userInitiated) {
             // If SettingsAccount has been presented modally, dismiss both
             // the CardCreator and the modal window.
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
      break;
    }
    case CellKindSyncButton: {
      break;
    }
    case CellKindAbout: {
      //GODO temp until OPDS link created
      break;
    }
    case CellKindPrivacyPolicy: {
      NYPLSettingsPrivacyPolicyViewController *vc = [[NYPLSettingsPrivacyPolicyViewController alloc] init];
      if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.splitViewController showDetailViewController:[[UINavigationController alloc]
                                        initWithRootViewController:vc]
                                sender:self];
      } else {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.splitViewController showDetailViewController:vc sender:self];
      }
      break;
    }
    case CellKindContentLicense: {
      NYPLSettingsContentLicenseViewController *vc = [[NYPLSettingsContentLicenseViewController alloc] init];
      if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.splitViewController showDetailViewController:[[UINavigationController alloc]
                                                            initWithRootViewController:vc]
                                                    sender:self];
      } else {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.splitViewController showDetailViewController:vc sender:self];
      }
      break;
    }
    case CellKindContact: {
      //GODO temp until further information
      break;
    }
  }
}

- (void)didSelectCancelForSignUp
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (CGFloat)tableView:(UITableView *)__unused tableView heightForHeaderInSection:(NSInteger)section
{
  if (section == 0) {
    return CGFLOAT_MIN;
  } else {
    return UITableViewAutomaticDimension;
  }
}


#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(__attribute__((unused)) UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *const)indexPath
{
  // This is the amount of horizontal padding Apple uses around the titles in cells by default.
  CGFloat const padding = 16;
  
  switch(CellKindFromIndexPath(indexPath)) {
    case CellKindAccountHeader: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleSubtitle
                                     reuseIdentifier:nil];
      Account *account = [[[Accounts alloc] init] account:self.account];
      cell.textLabel.font = [UIFont systemFontOfSize:14];
      cell.textLabel.text = account.name;
      cell.detailTextLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:12];
      cell.detailTextLabel.text = @"Subtitle will go here";
      
      UIView *backView = [[UIView alloc] initWithFrame:CGRectZero];
      backView.backgroundColor = [UIColor clearColor];
      cell.backgroundView = backView;
      cell.backgroundColor = [UIColor clearColor];

      cell.imageView.image = [UIImage imageNamed:account.logo];

      
      return cell;
    }
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
    case CellKindEULA: {
      self.eulaCell = [[UITableViewCell alloc]
                       initWithStyle:UITableViewCellStyleDefault
                       reuseIdentifier:nil];
      Account *accountItem = [[[Accounts alloc] init] account:self.account];
      if ([[NYPLSettings sharedSettings] userAcceptedEULAForAccount:accountItem] == YES) {
        self.eulaCell.accessoryView = [[UIImageView alloc] initWithImage:
                                       [UIImage imageNamed:@"CheckboxOn"]];
      } else {
        self.eulaCell.accessoryView = [[UIImageView alloc] initWithImage:
                                       [UIImage imageNamed:@"CheckboxOff"]];
      }
      self.eulaCell.selectionStyle = UITableViewCellSelectionStyleNone;
      self.eulaCell.textLabel.font = [UIFont systemFontOfSize:13];
      self.eulaCell.textLabel.text = NSLocalizedString(@"SettingsAccountEULACheckbox", @"Statement letting a user know that they must agree to the User Agreement terms.");
      self.eulaCell.textLabel.numberOfLines = 2;
      return self.eulaCell;
    }
    case CellKindLogInSignOut: {
      if(!self.logInSignOutCell) {
        self.logInSignOutCell = [[UITableViewCell alloc]
                                initWithStyle:UITableViewCellStyleDefault
                                reuseIdentifier:nil];
        self.logInSignOutCell.textLabel.font = [UIFont systemFontOfSize:17];
      }
      [self updateLoginLogoutCellAppearance];
      return self.logInSignOutCell;
    }
    case CellKindRegistration: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      cell.textLabel.font = [UIFont systemFontOfSize:17];
      cell.textLabel.text = NSLocalizedString(@"SignUp", nil);
      cell.textLabel.textColor = [NYPLConfiguration mainColor];
      return cell;
    }
    case CellKindSyncButton: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      UISwitch* switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
      if ([[NYPLSettings sharedSettings] accountSyncEnabled]) {
        [switchView setOn:YES];
      } else {
        [switchView setOn:NO];
      }
      cell.accessoryView = switchView;
      [switchView addTarget:self action:@selector(syncSwitchChanged:) forControlEvents:UIControlEventValueChanged];
      [cell.contentView addSubview:switchView];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      cell.textLabel.font = [UIFont systemFontOfSize:17];
      cell.textLabel.text = @"Sync Annotations";
      return cell;
    }
    case CellKindAbout: {
      Account *accountItem = [[[Accounts alloc] init] account:self.account];
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      cell.textLabel.font = [UIFont systemFontOfSize:17];
      cell.textLabel.text = [NSString stringWithFormat:@"About %@",accountItem.name];
      return cell;
    }
    case CellKindPrivacyPolicy: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      cell.textLabel.font = [UIFont systemFontOfSize:17];
      cell.textLabel.text = @"Privacy Policy";
      return cell;
    }
    case CellKindContentLicense: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      cell.textLabel.font = [UIFont systemFontOfSize:17];
      cell.textLabel.text = @"Content License";
      return cell;
    }
    case CellKindContact: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      cell.textLabel.font = [UIFont systemFontOfSize:17];
      cell.textLabel.text = @"Contact";
      return cell;
    }
  }
}

- (NSInteger)numberOfSectionsInTableView:(__attribute__((unused)) UITableView *)tableView
{
    
  if (![[[Accounts alloc] init] account:self.account].needsAuth) {
    return 0;
  } else if ([[NYPLSettings sharedSettings] annotationsURL]) {
    return 5;
  } else {
    return 4;
  }
}

- (NSInteger)tableView:(__attribute__((unused)) UITableView *)tableView
 numberOfRowsInSection:(NSInteger const)section
{
  switch(section) {
    case SectionAccountHeader:
      return 1;
    case SectionBarcodePin:
      return 2;
    case SectionEULA:
      if ([self registrationIsPossible]) {
        return 3;
      } else {
        return 2;
      }
    case SectionSyncOrLicenses:
      if ([[NYPLSettings sharedSettings] annotationsURL]) {
        return 1;
      } else {
        return 4;
      }
    case SectionLicenses:
      return 4;
    default:
      @throw NSInternalInconsistencyException;
  }
}

- (CGFloat)tableView:(__unused UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  switch (indexPath.section) {
    case 0:
      return 60;
    default:
      return 44;
  }
}

- (BOOL)textFieldShouldBeginEditing:(__unused UITextField *)textField
{
  return ![[NYPLAccount sharedAccount:self.account] hasBarcodeAndPIN];
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

- (BOOL)registrationIsPossible
{
  return !([[NYPLAccount sharedAccount:self.account] hasBarcodeAndPIN] ||
          ![NYPLConfiguration cardCreationEnabled]);
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
    if([NYPLAccount sharedAccount:self.account].hasBarcodeAndPIN) {
      self.barcodeTextField.text = [NYPLAccount sharedAccount:self.account].barcode;
      self.barcodeTextField.enabled = NO;
      self.barcodeTextField.textColor = [UIColor grayColor];
      self.PINTextField.text = [NYPLAccount sharedAccount:self.account].PIN;
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

- (void)changedCurrentAccount
{
  [self.navigationController popViewControllerAnimated:NO];
}

- (void)showEULA
{
  UIViewController *eulaViewController = [[NYPLSettingsEULAViewController alloc] init];
  UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:eulaViewController];
  [self.navigationController presentViewController:navVC animated:YES completion:nil];
}

- (void)updateLoginLogoutCellAppearance
{
  if([[NYPLAccount sharedAccount:self.account] hasBarcodeAndPIN]) {
    self.logInSignOutCell.textLabel.text = NSLocalizedString(@"SignOut", nil);
    self.logInSignOutCell.textLabel.textAlignment = NSTextAlignmentCenter;
    self.logInSignOutCell.textLabel.textColor = [NYPLConfiguration mainColor];
    self.logInSignOutCell.userInteractionEnabled = YES;
    self.eulaCell.userInteractionEnabled = NO;
  } else {
    self.eulaCell.userInteractionEnabled = YES;
    self.logInSignOutCell.textLabel.text = NSLocalizedString(@"LogIn", nil);
    self.logInSignOutCell.textLabel.textAlignment = NSTextAlignmentCenter;
    Account *accountItem = [[[Accounts alloc] init] account:self.account];
    BOOL const canLogIn =
      ([self.barcodeTextField.text
        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length &&
       [self.PINTextField.text
        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length) &&
      [[NYPLSettings sharedSettings] userAcceptedEULAForAccount:accountItem];
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

- (void)logOut
{
  void (^afterDeauthorization)() = ^() {
    
    [[NYPLMyBooksDownloadCenter sharedDownloadCenter] reset:self.account];
    [[NYPLBookRegistry sharedRegistry] reset:self.account];

    [[NYPLAccount sharedAccount:self.account] removeBarcodeAndPIN];
    [self.tableView reloadData];
  };
  
#if defined(FEATURE_DRM_CONNECTOR)
  if([NYPLADEPT sharedInstance].workflowsInProgress) {
    [self presentViewController:[NYPLAlertController
                                 alertWithTitle:@"SettingsAccountViewControllerCannotLogOutTitle"
                                 message:@"SettingsAccountViewControllerCannotLogOutMessage"]
                       animated:YES
                     completion:nil];
    return;
  }
  
  [self setActivityTitleWithText:NSLocalizedString(@"SigningOut", nil)];
  [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
  
  [[NYPLReachability sharedReachability]
   reachabilityForURL:[NYPLConfiguration circulationURL]
   timeoutInternal:5.0
   handler:^(BOOL reachable) {
     if(reachable) {
       [[NYPLADEPT sharedInstance]
        deauthorizeWithUsername:[[NYPLAccount sharedAccount:self.account] barcode]
        password:[[NYPLAccount sharedAccount:self.account] PIN]
        completion:^(BOOL success, __unused NSError *error) {
          if(!success) {
            // Even though we failed, all we do is log the error. The reason is
            // that we want the user to be able to log out anyway because the
            // failure is probably due to bad credentials and we do not want the
            // user to have to change their barcode or PIN just to log out. This
            // is only a temporary measure and we'll switch to deauthorizing with
            // a token that will remain invalid indefinitely in the near future.
            NYPLLOG(@"Failed to deauthorize successfully.");
          }
          [self removeActivityTitle];
          [[UIApplication sharedApplication] endIgnoringInteractionEvents];
          afterDeauthorization();
        }];
     } else {
       [[NSOperationQueue mainQueue] addOperationWithBlock:^{
         [self removeActivityTitle];
         [[UIApplication sharedApplication] endIgnoringInteractionEvents];
         [self presentViewController:[NYPLAlertController
                                      alertWithTitle:@"SettingsAccountViewControllerLogoutFailed"
                                      message:@"TimedOut"]
                            animated:YES
                          completion:nil];
       }];
     }
   }];
#else
  afterDeauthorization();
#endif
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
  
  NSURLSessionDataTask *const task =
    [self.session
     dataTaskWithRequest:request
     completionHandler:^(__attribute__((unused)) NSData *data,
                         NSURLResponse *const response,
                         NSError *const error) {
       
       if (self.isLoggingInAfterSignUp) {
         [[NSNotificationCenter defaultCenter] postNotificationName:NYPLSettingsAccountsSignInFinishedNotification
                                                             object:self];
       }
       
       // This cast is always valid according to Apple's documentation for NSHTTPURLResponse.
       NSInteger const statusCode = ((NSHTTPURLResponse *) response).statusCode;
       
       // Success.
       if(statusCode == 200) {
         
         
         //AM_FIXME
         
#if defined(FEATURE_DRM_CONNECTOR)
         [[NYPLADEPT sharedInstance]
          authorizeWithVendorID:@"NYPL"
          username:self.barcodeTextField.text
          password:self.PINTextField.text
          completion:^(BOOL success, NSError *error) {
            [self authorizationAttemptDidFinish:success error:error];
          }];
#else
         [self authorizationAttemptDidFinish:YES error:nil];
#endif
         
         
         
         
         
         
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
       
       self.barcodeTextField.text = nil;
       self.PINTextField.text = nil;
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
  [[NSNotificationCenter defaultCenter] postNotificationName:NYPLSettingsAccountsSignInFinishedNotification
                                                      object:self];
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

- (void)syncSwitchChanged:(id)sender
{
  UISwitch *switchControl = sender;
  if (switchControl.on) {
    [[NYPLSettings sharedSettings] setAccountSyncEnabled:YES];
  } else {
    [[NYPLSettings sharedSettings] setAccountSyncEnabled:NO];
  }
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
      [[NYPLAccount sharedAccount:self.account] setBarcode:self.barcodeTextField.text
                                          PIN:self.PINTextField.text];

      if(self.account == [[NYPLSettings sharedSettings] currentAccountIdentifier]) {
        if (!self.isLoggingInAfterSignUp) {
          [self dismissViewControllerAnimated:YES completion:nil];
        }
        void (^handler)() = self.completionHandler;
        self.completionHandler = nil;
        if(handler) handler();
        [[NYPLBookRegistry sharedRegistry] syncWithCompletionHandler:nil];
      }
      
    } else {
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