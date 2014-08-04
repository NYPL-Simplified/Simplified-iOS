#import "NYPLAccount.h"
#import "NYPLSettingsCredentialViewController.h"

#import "NYPLSettingsViewController.h"

@interface NYPLSettingsViewController () <UITextFieldDelegate>

@property (nonatomic) UILabel *barcodeLabel;
@property (nonatomic) UIButton *logInButton;
@property (nonatomic) UIButton *logOutButton;
@property (nonatomic) UILabel *PINLabel;

@end

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
  self.view.backgroundColor = [UIColor whiteColor];
  
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
  
  [self updateAppearance];
}

- (void)viewWillLayoutSubviews
{
  [self.barcodeLabel sizeToFit];
  self.barcodeLabel.frame = CGRectMake(5,
                                       69,
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
                                      69,
                                      CGRectGetWidth(self.logInButton.frame),
                                      CGRectGetHeight(self.logInButton.frame));
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *const)alertView
didDismissWithButtonIndex:(NSInteger const)buttonIndex
{
  if(buttonIndex == alertView.firstOtherButtonIndex) {
    [[NYPLAccount sharedAccount] removeBarcodeAndPIN];
  }
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
