#import "NYPLSettingsCredentialView.h"

#import "NYPLSettingsCredentialViewController.h"

@interface NYPLSettingsCredentialViewController ()

@property (nonatomic) NYPLSettingsCredentialView *credentialView;
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

#pragma mark UIViewController

- (void)viewWillAppear:(__attribute__((unused)) BOOL)animated
{

}

- (void)viewDidAppear:(__attribute__((unused)) BOOL)animated
{
  [((NYPLSettingsCredentialView *) self.view).barcodeField becomeFirstResponder];
}

#pragma mark -

- (void)requestCredentialsFromViewController:(UIViewController *)viewController
{
  self.modalPresentationStyle = UIModalPresentationFormSheet;
  
  [viewController presentViewController:self animated:YES completion:^{}];
}

@end
