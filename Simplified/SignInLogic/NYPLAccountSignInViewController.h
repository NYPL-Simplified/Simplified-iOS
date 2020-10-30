@import UIKit;

@class NYPLSignInBusinessLogic;

/// This class handles all instances of signing into current account dynamically in many
/// places in the app when necessary. Managing account sign in with settings is
/// NYPLSettingsAccountDetailViewController.
@interface NYPLAccountSignInViewController : UITableViewController

- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

@property(readonly) NYPLSignInBusinessLogic *businessLogic;

/**
 * Presents itself to begin the login process.
 *
 * @param useExistingBarcode Should the screen be filled with the barcode when available?
 * @param authorizeImmediately Should the authentication process begin automatically after presenting? For Oauth2 and SAML it would mean opening a webview.
 * @param completionHandler Called upon successful authentication
 */
- (void)presentUsingExistingBarcode:(BOOL const)useExistingBarcode
               authorizeImmediately:(BOOL)authorizeImmediately
                  completionHandler:(void (^)(void))handler;

/**
 * Present sign in view controller to begin a login process.
 *
 * @param useExistingBarcode      Should the screen be filled with barcode and pin when available?
 * @param authorizeImmediately  Should the authentication process begin automatically after presenting? For Oauth2 and SAML it would mean opening a webview
 * @param completionHandler Called upon successful authentication.
 */
+ (void)requestCredentialsUsingExistingBarcode:(BOOL const)useExistingCredentials
                          authorizeImmediately:(BOOL)authorizeImmediately
                             completionHandler:(void (^)(void))handler;

// TODO: All calls to this method probably should go through NYPLAccount.
// The existing barcode may only be used if set in the shared NYPLAccount.
+ (void)requestCredentialsUsingExistingBarcode:(BOOL)useExistingBarcode
                             completionHandler:(void (^)(void))handler;

// This method is here almost entirely so we can handle a bug that seems to occur
// when the user updates, where the barcode and pin are entered but accoring to
// ADEPT the device is not authorized. To be used, the account must have a barcode
// and pin.
+ (void)authorizeUsingExistingBarcodeAndPinWithCompletionHandler:(void (^)(void))handler;

@end
