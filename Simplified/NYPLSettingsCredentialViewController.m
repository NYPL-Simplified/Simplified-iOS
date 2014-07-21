#import "NYPLSettingsCredentialView.h"

#import "NYPLSettingsCredentialViewController.h"

@interface NYPLSettingsCredentialViewController ()

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
  
  return self;
}

- (void)viewWillAppear:(__attribute__((unused)) BOOL)animated
{

}

- (void)viewDidAppear:(__attribute__((unused)) BOOL)animated
{
  [self.credentialView.barcodeField becomeFirstResponder];
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

@end
