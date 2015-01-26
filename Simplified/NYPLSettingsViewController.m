#import "NYPLAccount.h"
#import "NYPLMyBooksCoverRegistry.h"
#import "NYPLConfiguration.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLMyBooksRegistry.h"
#import "NYPLSettingsCredentialViewController.h"

#import "NYPLSettingsViewController.h"

@interface NYPLSettingsViewController () <UIAlertViewDelegate, UITextFieldDelegate>

@property (nonatomic) UILabel *barcodeLabel;
@property (nonatomic) UITextField *developmentOPDSURLTextField;
@property (nonatomic) UIButton *logInButton;
@property (nonatomic) UIButton *logOutButton;
@property (nonatomic) UILabel *PINLabel;

@end

static NSString *const developmentOPDSURLKey = @"developmentOPDSURL";

@implementation NYPLSettingsViewController

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.title = NSLocalizedString(@"SettingsViewControllerTitle", nil);
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(updateAppearance)
   name:NYPLAccountDidChangeNotification
   object:nil];
  
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
  
  self.barcodeLabel = [[UILabel alloc] init];
  [self.view addSubview:self.barcodeLabel];
  
  self.PINLabel = [[UILabel alloc] init];
  [self.view addSubview:self.PINLabel];
  
  self.logInButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.logInButton addTarget:self
                        action:@selector(didSelectLogIn)
              forControlEvents:UIControlEventTouchUpInside];
  [self.logInButton setTitle:NSLocalizedString(@"LogIn", nil) forState:UIControlStateNormal];
  [self.view addSubview:self.logInButton];
  
  self.logOutButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.logOutButton addTarget:self
                        action:@selector(didSelectLogOut)
              forControlEvents:UIControlEventTouchUpInside];
  [self.logOutButton setTitle:NSLocalizedString(@"LogOut", nil) forState:UIControlStateNormal];
  [self.view addSubview:self.logOutButton];
  
  self.developmentOPDSURLTextField = [[UITextField alloc] initWithFrame:CGRectZero];
  self.developmentOPDSURLTextField.delegate = self;
  self.developmentOPDSURLTextField.borderStyle = UITextBorderStyleRoundedRect;
  self.developmentOPDSURLTextField.placeholder = @"Enter a custom OPDS URL…";
  self.developmentOPDSURLTextField.keyboardType = UIKeyboardTypeURL;
  self.developmentOPDSURLTextField.returnKeyType = UIReturnKeyDone;
  self.developmentOPDSURLTextField.spellCheckingType = UITextSpellCheckingTypeNo;
  self.developmentOPDSURLTextField.autocorrectionType = UITextAutocorrectionTypeNo;
  self.developmentOPDSURLTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
  self.developmentOPDSURLTextField.text = [[NSUserDefaults standardUserDefaults]
                                           valueForKey:@"developmentOPDSURL"];
  [self.view addSubview:self.developmentOPDSURLTextField];
  
  
  [self updateAppearance];
}

- (void)viewWillAppear:(__attribute__((unused)) BOOL)animated
{
  self.developmentOPDSURLTextField.text = [[NYPLConfiguration developmentFeedURL] absoluteString];
}

- (void)viewWillLayoutSubviews
{
  [self.developmentOPDSURLTextField sizeToFit];
  self.developmentOPDSURLTextField.frame =
    CGRectMake(5,
               69,
               CGRectGetWidth(self.view.frame) - 10,
               CGRectGetHeight(self.developmentOPDSURLTextField.frame));
  
  [self.barcodeLabel sizeToFit];
  self.barcodeLabel.frame = CGRectMake(5,
                                       CGRectGetMaxY(self.developmentOPDSURLTextField.frame) + 5,
                                       CGRectGetWidth(self.barcodeLabel.frame),
                                       CGRectGetHeight(self.barcodeLabel.frame));
  
  [self.PINLabel sizeToFit];
  self.PINLabel.frame = CGRectMake(5,
                                   CGRectGetMaxY(self.barcodeLabel.frame) + 5,
                                   CGRectGetWidth(self.PINLabel.frame),
                                   CGRectGetHeight(self.PINLabel.frame));
  
  [self.logOutButton sizeToFit];
  self.logOutButton.frame = CGRectMake(5,
                                       CGRectGetMaxY(self.PINLabel.frame) + 5,
                                       CGRectGetWidth(self.logOutButton.frame),
                                       CGRectGetHeight(self.logOutButton.frame));
  
  [self.logInButton sizeToFit];
  self.logInButton.frame = CGRectMake(5,
                                      CGRectGetMaxY(self.developmentOPDSURLTextField.frame) + 5,
                                      CGRectGetWidth(self.logInButton.frame),
                                      CGRectGetHeight(self.logInButton.frame));
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *const)alertView
didDismissWithButtonIndex:(NSInteger const)buttonIndex
{
  if(buttonIndex == alertView.firstOtherButtonIndex) {
    [[NYPLMyBooksCoverRegistry sharedRegistry] removeAllPinnedThumbnailImages];
    [[NYPLMyBooksDownloadCenter sharedDownloadCenter] reset];
    [[NYPLMyBooksRegistry sharedRegistry] reset];
    [[NYPLAccount sharedAccount] removeBarcodeAndPIN];
  }
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *const)textField
{
  [self.developmentOPDSURLTextField resignFirstResponder];
  
  NSString *const feed = [textField.text stringByTrimmingCharactersInSet:
                          [NSCharacterSet whitespaceCharacterSet]];
  
  if(feed.length) {
    [NYPLConfiguration setDevelopmentFeedURL:[NSURL URLWithString:textField.text]];
  } else {
    [NYPLConfiguration setDevelopmentFeedURL:nil];
  }
  
  [[[UIAlertView alloc]
    initWithTitle:@"Restart Required"
    message:(@"In order for this development-only feature to have an effect, you must "
             @"force quit and restart this application.")
    delegate:nil
    cancelButtonTitle:nil
    otherButtonTitles:@"OK", nil]
   show];
  
  return YES;
}

#pragma mark -

- (void)updateAppearance
{
  if([[NYPLAccount sharedAccount] hasBarcodeAndPIN]) {
    self.barcodeLabel.hidden = NO;
    self.barcodeLabel.text = [NYPLAccount sharedAccount].barcode;
    self.PINLabel.hidden = NO;
    self.PINLabel.text = [NYPLAccount sharedAccount].PIN;
    self.logInButton.hidden = YES;
    self.logOutButton.hidden = NO;
  } else {
    self.barcodeLabel.hidden = YES;
    self.PINLabel.hidden = YES;
    self.logInButton.hidden = NO;
    self.logOutButton.hidden = YES;
  }
  
  [self.view setNeedsLayout];
}

- (void)didSelectLogIn
{
  [[NYPLSettingsCredentialViewController sharedController]
   requestCredentialsUsingExistingBarcode:NO
   message:NYPLSettingsCredentialViewControllerMessageLogIn
   completionHandler:nil];
}

- (void)didSelectLogOut
{
  [[[UIAlertView alloc]
    initWithTitle:NSLocalizedString(@"LogOut", nil)
    message:NSLocalizedString(@"SettingsViewControllerLogoutMessage", nil)
    delegate:self
    cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
    otherButtonTitles:NSLocalizedString(@"LogOut", nil), nil]
   show];
}

@end
