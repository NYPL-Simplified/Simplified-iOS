@interface NYPLSettingsCredentialViewController : UIViewController

+ (instancetype)sharedController;

// The provided handler will be called iff the user enters their credentials and chooses to
// continue. It will not be called upon canceling. This method must never be called when the view
// controller is already visible. Neither argument may be nil.
- (void)requestCredentialsFromViewController:(UIViewController *)viewController
                           completionHandler:(void (^)())handler;

@end
