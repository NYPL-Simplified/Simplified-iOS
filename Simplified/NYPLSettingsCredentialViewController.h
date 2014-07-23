typedef NS_ENUM(NSInteger, NYPLSettingsCredentialViewControllerMessage) {
  NYPLSettingsCredentialViewControllerMessageLogIn,
  NYPLSettingsCredentialViewControllerMessageLogInToDownloadBook,
  NYPLSettingsCredentialViewControllerMessageInvalidPin
};

@interface NYPLSettingsCredentialViewController : UIViewController

+ (instancetype)sharedController;

// This method must not be called while the view controller is displayed. No arguments may be nil.
// The existing barcode may only be used if set in the shared NYPLAccount.
- (void)requestCredentialsFromViewController:(UIViewController *)viewController
                          useExistingBarcode:(BOOL)useExistingBarcode
                                     message:(NYPLSettingsCredentialViewControllerMessage)message
                           completionHandler:(void (^)())handler;

@end
