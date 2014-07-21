#import "NYPLKeychain.h"
#import "NYPLSettings.h"
#import "NYPLSettingsCredentialView.h"

#import "NYPLSettingsCredentialViewController.h"

@interface NYPLSettingsCredentialViewController () <UITextFieldDelegate>

@property (nonatomic, readonly) NYPLSettingsCredentialView *credentialView;
@property (nonatomic, copy) void (^completionHandler)();
@property (nonatomic) UIViewController *viewController;

@end

@implementation NYPLSettingsCredentialViewController

+ (instancetype)sharedController
{
  static dispatch_once_t predicate;
  static NYPLSettingsCredentialViewController *sharedController;
  
  dispatch_once(&predicate, ^{
    sharedController = [[self alloc] initWithNibName:@"NYPLSettingsCredentialView"
                                              bundle:[NSBundle mainBundle]];
    if(!sharedController) {
      NYPLLOG(@"Failed to create shared settings credential controller.");
    }
  });
  
  return sharedController;
}

- (NYPLSettingsCredentialView *)credentialView
{
  return (NYPLSettingsCredentialView *)self.view;
}

#pragma mark UIViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil
                         bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if(!self) return nil;
  
  self.credentialView.navigationItem.leftBarButtonItem.action = @selector(didSelectCancel);
  self.credentialView.navigationItem.leftBarButtonItem.target = self;
  
  self.credentialView.navigationItem.rightBarButtonItem.action = @selector(didSelectContinue);
  self.credentialView.navigationItem.rightBarButtonItem.target = self;
  
  [self.credentialView.barcodeField
   addTarget:self
   action:@selector(fieldsDidChange)
   forControlEvents:UIControlEventEditingChanged];
  
  self.credentialView.barcodeField.delegate = self;
  
  [self.credentialView.PINField
   addTarget:self
   action:@selector(fieldsDidChange)
   forControlEvents:UIControlEventEditingChanged];
  
  self.credentialView.PINField.delegate = self;
  
  return self;
}

- (void)viewWillAppear:(__attribute__((unused)) BOOL)animated
{
  self.credentialView.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)viewDidAppear:(__attribute__((unused)) BOOL)animated
{
  [self.credentialView.barcodeField becomeFirstResponder];
}

#pragma mark UITextViewDelegate

- (BOOL)textFieldShouldReturn:(UITextField *const)textField
{
  if(textField == self.credentialView.barcodeField) {
    [self.credentialView.PINField becomeFirstResponder];
  } else {
    [self.credentialView.PINField resignFirstResponder];
  }
  
  return YES;
}

#pragma mark -

- (void)requestCredentialsFromViewController:(UIViewController *const)viewController
                           completionHandler:(void (^)())handler
{
  if(!(viewController && handler)) {
    @throw NSInvalidArgumentException;
  }
  
  if(self.completionHandler) {
    @throw NSInternalInconsistencyException;
  }
  
  self.completionHandler = handler;
  
  self.modalPresentationStyle = UIModalPresentationFormSheet;
  
  [viewController presentViewController:self animated:YES completion:^{}];
}

- (void)didSelectCancel
{
  [self dismissViewControllerAnimated:YES completion:^{}];
  
  self.completionHandler = nil;
}

- (void)didSelectContinue
{
  [self dismissViewControllerAnimated:YES completion:^{}];
  
  void (^handler)() = self.completionHandler;
  self.completionHandler = nil;
  handler();
}

- (void)fieldsDidChange
{
  // TODO: This code is very similar to the |fieldsDidChange| method in NYPLSettingsViewController.
  // It should probably be factored out somehow.
  
  NSString *const barcode = self.credentialView.barcodeField.text;
  if(barcode) {
    [[NYPLKeychain sharedKeychain] setObject:[barcode length] > 0 ? barcode : nil
                                      forKey:NYPLSettingsBarcodeKey];
  }
  
  NSString *const PIN = self.credentialView.PINField.text;
  if(PIN) {
    [[NYPLKeychain sharedKeychain] setObject:[PIN length] > 0 ? PIN : nil
                                      forKey:NYPLSettingsPINKey];
  }
  
  self.credentialView.navigationItem.rightBarButtonItem.enabled =
    [barcode length] > 0 && [PIN length] > 0;
}

@end
