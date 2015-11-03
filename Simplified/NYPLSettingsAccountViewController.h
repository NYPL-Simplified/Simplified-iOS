@interface NYPLSettingsAccountViewController : UITableViewController

- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

// TODO: All calls to this method probably should go through NYPLAccount.
// The existing barcode may only be used if set in the shared NYPLAccount.
+ (void)requestCredentialsUsingExistingBarcode:(BOOL)useExistingBarcode
                             completionHandler:(void (^)())handler;

// This method is here almost entirely so we can handle a bug that seems to occur
// when the user updates, where the barcode and pin are entered but accoring to
// ADEPT the device is not authorized. To be used, the account must hace a barcode and pin
+ (void)authorizeUsingExistingBarcodeAndPinWithCompletionHandler:(void (^)())handler;

@end
