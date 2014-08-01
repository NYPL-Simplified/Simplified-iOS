typedef NS_ENUM(NSInteger, NYPLSettingsCredentialViewControllerMessage) {
  NYPLSettingsCredentialViewControllerMessageLogIn,
  NYPLSettingsCredentialViewControllerMessageLogInToDownloadBook,
  NYPLSettingsCredentialViewControllerMessageInvalidPin
};

@interface NYPLSettingsCredentialViewController : UIViewController

+ (instancetype)sharedController;

// The existing barcode may only be used if set in the shared NYPLAccount.
- (void)requestCredentialsUsingExistingBarcode:(BOOL)useExistingBarcode
                                       message:(NYPLSettingsCredentialViewControllerMessage)message
                             completionHandler:(void (^)())handler;

@end
