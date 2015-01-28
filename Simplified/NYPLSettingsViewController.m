#import "NYPLAccount.h"
#import "NYPLMyBooksCoverRegistry.h"
#import "NYPLConfiguration.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLMyBooksRegistry.h"
#import "NYPLRoundedButton.h"
#import "NYPLSettings.h"
#import "NYPLSettingsCredentialViewController.h"

#import "NYPLSettingsViewController.h"

@interface NYPLSettingsViewController () <UIAlertViewDelegate, UITextFieldDelegate>

@property (nonatomic) UILabel *barcodeLabel;
@property (nonatomic) UITextField *developmentOPDSURLTextField;
@property (nonatomic) UIButton *logInButton;
@property (nonatomic) UIButton *logOutButton;
@property (nonatomic) UILabel *PINLabel;
@property (nonatomic) UIButton *renderingEngineButton;

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
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(updateAppearance)
   name:NYPLSettingsDidChangeNotification
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
  
  self.logInButton = [NYPLRoundedButton button];
  [self.logInButton addTarget:self
                        action:@selector(didSelectLogIn)
              forControlEvents:UIControlEventTouchUpInside];
  [self.logInButton setTitle:NSLocalizedString(@"LogIn", nil) forState:UIControlStateNormal];
  [self.view addSubview:self.logInButton];
  
  self.logOutButton = [NYPLRoundedButton button];
  [self.logOutButton addTarget:self
                        action:@selector(didSelectLogOut)
              forControlEvents:UIControlEventTouchUpInside];
  [self.logOutButton setTitle:NSLocalizedString(@"LogOut", nil) forState:UIControlStateNormal];
  [self.view addSubview:self.logOutButton];
  
  self.developmentOPDSURLTextField = [[UITextField alloc] initWithFrame:CGRectZero];
  self.developmentOPDSURLTextField.delegate = self;
  self.developmentOPDSURLTextField.borderStyle = UITextBorderStyleRoundedRect;
  self.developmentOPDSURLTextField.placeholder = @"Enter a custom HTTP OPDS URL…";
  self.developmentOPDSURLTextField.keyboardType = UIKeyboardTypeURL;
  self.developmentOPDSURLTextField.returnKeyType = UIReturnKeyDone;
  self.developmentOPDSURLTextField.spellCheckingType = UITextSpellCheckingTypeNo;
  self.developmentOPDSURLTextField.autocorrectionType = UITextAutocorrectionTypeNo;
  self.developmentOPDSURLTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
  [self.view addSubview:self.developmentOPDSURLTextField];
  
  self.renderingEngineButton = [NYPLRoundedButton button];
  [self.renderingEngineButton addTarget:self
                                 action:@selector(didSelectRenderingEngine)
                       forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:self.renderingEngineButton];
}

- (void)viewWillAppear:(__attribute__((unused)) BOOL)animated
{
  [self updateAppearance];
}

- (void)viewWillLayoutSubviews
{
  if([[NYPLAccount sharedAccount] hasBarcodeAndPIN]) {
    [self.barcodeLabel sizeToFit];
    self.barcodeLabel.frame =
      CGRectMake(5,
                 CGRectGetMaxY(self.navigationController.navigationBar.frame) + 5,
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
    
    [self.developmentOPDSURLTextField sizeToFit];
    self.developmentOPDSURLTextField.frame =
      CGRectMake(5,
                 CGRectGetMaxY(self.logOutButton.frame) + 5,
                 CGRectGetWidth(self.view.frame) - 10,
                 CGRectGetHeight(self.developmentOPDSURLTextField.frame));
  } else {
    [self.logInButton sizeToFit];
    self.logInButton.frame =
      CGRectMake(5,
                 CGRectGetMaxY(self.navigationController.navigationBar.frame) + 5,
                 CGRectGetWidth(self.logInButton.frame),
                 CGRectGetHeight(self.logInButton.frame));
    
    [self.developmentOPDSURLTextField sizeToFit];
      self.developmentOPDSURLTextField.frame =
      CGRectMake(5,
                 CGRectGetMaxY(self.logInButton.frame) + 5,
                 CGRectGetWidth(self.view.frame) - 10,
                 CGRectGetHeight(self.developmentOPDSURLTextField.frame));
  }
  
  [self.renderingEngineButton sizeToFit];
  
  self.renderingEngineButton.frame =
    CGRectMake(5,
               CGRectGetMaxY(self.developmentOPDSURLTextField.frame) + 5,
               CGRectGetWidth(self.renderingEngineButton.frame),
               CGRectGetHeight(self.renderingEngineButton.frame));
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
    [NYPLSettings sharedSettings].customMainFeedURL = [NSURL URLWithString:feed];
  } else {
    [NYPLSettings sharedSettings].customMainFeedURL = nil;
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
    self.barcodeLabel.text = [@"Barcode: " stringByAppendingString:
                              [NYPLAccount sharedAccount].barcode];
    self.PINLabel.hidden = NO;
    self.PINLabel.text = [@"PIN: " stringByAppendingString:[NYPLAccount sharedAccount].PIN];
    self.logInButton.hidden = YES;
    self.logOutButton.hidden = NO;
  } else {
    self.barcodeLabel.hidden = YES;
    self.PINLabel.hidden = YES;
    self.logInButton.hidden = NO;
    self.logOutButton.hidden = YES;
  }
  
  self.developmentOPDSURLTextField.text =
    [NYPLSettings sharedSettings].customMainFeedURL.absoluteString;
  
  NSString *renderingEngineString;
  switch([NYPLSettings sharedSettings].renderingEngine) {
    case NYPLSettingsRenderingEngineAutomatic:
      renderingEngineString = @"Automatic";
      break;
    case NYPLSettingsRenderingEngineReadium:
      renderingEngineString = @"Readium";
      break;
    case NYPLSettingsRenderingEngineRMSDK10:
      renderingEngineString = @"RMSDK 10";
      break;
  }
  
  [self.renderingEngineButton setTitle:[@"Rendering Engine: "
                                        stringByAppendingString:renderingEngineString]
                              forState:UIControlStateNormal];
  
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

- (void)didSelectRenderingEngine
{
  NYPLSettingsRenderingEngine const renderingEngine = [NYPLSettings sharedSettings].renderingEngine;
  
  UIAlertController *const alertController = [UIAlertController
                                              alertControllerWithTitle:nil
                                              message:nil
                                              preferredStyle:UIAlertControllerStyleActionSheet];
  
  [alertController addAction:[UIAlertAction
                              actionWithTitle:@"Automatic"
                              style:(renderingEngine == NYPLSettingsRenderingEngineAutomatic
                                     ? UIAlertActionStyleCancel
                                     : UIAlertActionStyleDefault)
                              handler:^(__attribute__((unused)) UIAlertAction *action) {
                                [NYPLSettings sharedSettings].renderingEngine =
                                  NYPLSettingsRenderingEngineAutomatic;
                              }]];
  
  [alertController addAction:[UIAlertAction
                              actionWithTitle:@"Readium"
                              style:(renderingEngine == NYPLSettingsRenderingEngineReadium
                                     ? UIAlertActionStyleCancel
                                     : UIAlertActionStyleDefault)
                              handler:^(__attribute__((unused)) UIAlertAction *action) {
                                [NYPLSettings sharedSettings].renderingEngine =
                                  NYPLSettingsRenderingEngineReadium;
                              }]];
  
  [alertController addAction:[UIAlertAction
                              actionWithTitle:@"RMSDK 10"
                              style:(renderingEngine == NYPLSettingsRenderingEngineRMSDK10
                                     ? UIAlertActionStyleCancel
                                     : UIAlertActionStyleDefault)
                              handler:^(__attribute__((unused)) UIAlertAction *action) {
                                [NYPLSettings sharedSettings].renderingEngine =
                                  NYPLSettingsRenderingEngineRMSDK10;
                              }]];
  
  alertController.popoverPresentationController.sourceRect = self.renderingEngineButton.bounds;
  alertController.popoverPresentationController.sourceView = self.renderingEngineButton;
  
  [self presentViewController:alertController animated:YES completion:nil];
}

@end
