@interface NYPLSettingsAccountViewController : UITableViewController

- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

// TODO: All calls to this method probably should go through NYPLAccount.
// The existing barcode may only be used if set in the shared NYPLAccount.
- (void)requestCredentialsUsingExistingBarcode:(BOOL)useExistingBarcode
                             completionHandler:(void (^)())handler;

@end
