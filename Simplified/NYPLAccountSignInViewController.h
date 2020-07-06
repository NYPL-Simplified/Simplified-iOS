/// This class handles all instances of signing into current account dynamically in many
/// places in the app when necessary. Managing account sign in with settings is
/// NYPLSettingsAccountDetailViewController.
@interface NYPLAccountSignInViewController : UITableViewController
@property (nonatomic, copy) void (^completionHandler)(void);

- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

// TODO: All calls to this method probably should go through NYPLAccount.
// The existing barcode may only be used if set in the shared NYPLAccount.
+ (void)requestCredentialsUsingExistingBarcode:(BOOL)useExistingBarcode
                             completionHandler:(void (^)(void))handler;

// This method is here almost entirely so we can handle a bug that seems to occur
// when the user updates, where the barcode and pin are entered but accoring to
// ADEPT the device is not authorized. To be used, the account must have a barcode
// and pin.
+ (void)authorizeUsingExistingBarcodeAndPinWithCompletionHandler:(void (^)(void))handler;

+ (void)authorizeUsingIntermediaryWithCompletionHandler:(void (^)(void))handler;

@end
