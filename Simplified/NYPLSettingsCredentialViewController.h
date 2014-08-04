typedef NS_ENUM(NSInteger, NYPLSettingsCredentialViewControllerMessage) {
  NYPLSettingsCredentialViewControllerMessageLogIn,
  NYPLSettingsCredentialViewControllerMessageLogInToDownloadBook,
  NYPLSettingsCredentialViewControllerMessageInvalidPin
};

@interface NYPLSettingsCredentialViewController : UIViewController

+ (instancetype)sharedController;

// TODO: All calls to this method probably should go through NYPLAccount.
// The existing barcode may only be used if set in the shared NYPLAccount.
- (void)requestCredentialsUsingExistingBarcode:(BOOL)useExistingBarcode
                                       message:(NYPLSettingsCredentialViewControllerMessage)message
                             completionHandler:(void (^)())handler;

@end
