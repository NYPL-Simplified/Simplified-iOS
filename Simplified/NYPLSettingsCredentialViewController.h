@interface NYPLSettingsCredentialViewController : UIViewController

+ (instancetype)sharedController;

- (void)requestCredentialsFromViewController:(UIViewController *)viewController;

@end
