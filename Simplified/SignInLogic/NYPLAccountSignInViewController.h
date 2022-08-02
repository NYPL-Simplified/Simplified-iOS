@import UIKit;

@class NYPLSignInBusinessLogic;

/// This class handles all instances of signing into current account dynamically in many
/// places in the app when necessary. Managing account sign in with settings is
/// NYPLSettingsAccountDetailViewController.
@interface NYPLAccountSignInViewController : UITableViewController

- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

@property(readonly) NYPLSignInBusinessLogic *businessLogic;

/// There are situations where the user appears signed in, but their
/// credentials are expired. In that case, it is desired to show the
/// sign-in modal with prefilled yet editable values. This flag provides
/// a way to do so in conjuction with the @p isSignedIn() function on
/// the @p NYPLSignInBusinessLogic.
@property BOOL forceEditability;

/**
 * Presents itself to begin the login process.
 *
 * It's not recommended to use this api unless the following conditions
 * are both true:
 * - you are certain the user is logged out;
 * - you need to perform some additional customization before presenting the VC.
 *
 * In all other cases you should use the @p NYPLReauthenticator class.
 *
 * @param useExistingCredentials Should the screen be filled with the barcode when available?
 * @param completionHandler Called upon successful authentication
 */
- (void)presentIfNeededUsingExistingCredentials:(BOOL const)useExistingBarcode
                              refreshCompletion:(void (^)(void))completionHandler;

@end
