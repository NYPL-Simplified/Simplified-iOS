#import "SimplyE-Swift.h"
#import "NYPLCatalogFeedViewController.h"
#import "NYPLCatalogNavigationController.h"
#import "NYPLAccountSignInViewController.h"
#import "NYPLBookRegistry.h"
#import "NYPLRootTabBarController.h"
#import "NSString+NYPLStringAdditions.h"

@interface NYPLCatalogNavigationController()

@property (nonatomic) UIViewController *const feedVC;

@end


@implementation NYPLCatalogNavigationController

#pragma mark - Catalog loading

/// Replaces the current view controllers on the navigation stack with a single
/// view controller pointed at the current catalog URL.
- (void)loadTopLevelCatalogViewController
{
  if (![NSThread isMainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self loadTopLevelCatalogViewControllerInternal];
    });
  } else {
    [self loadTopLevelCatalogViewControllerInternal];
  }
}

- (void)loadTopLevelCatalogViewControllerInternal
{
  // TODO: SIMPLY-2862
  // unfortunately it's possible to get here with a nil feed URL at startup.
  // This is the result of an early initialization of the navigation controller
  // while the account is not yet set up. While this is definitely not
  // ideal, in my observations this seems to always be followed by
  // another `load` command once the authentication document is received.
  NSURL *catalogURL = [self topLevelCatalogURL];
  NYPLLOG_F(@"topLevelCatalogURL: %@", catalogURL);
  self.feedVC = [[NYPLCatalogFeedViewController alloc] initWithURL:catalogURL];
  self.feedVC.title = NSLocalizedString(@"Catalog", nil);

#ifdef SIMPLYE
  self.feedVC.navigationItem.title = [AccountsManager shared].currentAccount.name;
  [self setNavigationLeftBarButtonForVC:self.feedVC];
#endif

  self.feedVC.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Catalog", nil) style:UIBarButtonItemStylePlain target:nil action:nil];

  self.viewControllers = @[self.feedVC];
}

- (NSURL *)topLevelCatalogURL
{
  return [[NYPLSettings sharedSettings] accountMainFeedURL];
}

#pragma mark - NSObject

- (instancetype)init
{
  self = [super init];
  
  self.tabBarItem.title = NSLocalizedString(@"Catalog", nil);
  self.tabBarItem.image = [UIImage imageNamed:@"Catalog"];

  if ([self topLevelCatalogURL] != nil) {
    [self loadTopLevelCatalogViewController];
  }
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentAccountChanged) name:NSNotification.NYPLCurrentAccountDidChange object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncBegan) name:NSNotification.NYPLSyncBegan object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncEnded) name:NSNotification.NYPLSyncEnded object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSignOut) name:NSNotification.NYPLDidSignOut object:nil];

  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Account change logic

- (void)currentAccountChanged
{
  [self loadTopLevelCatalogViewController];
}

#ifdef SIMPLYE
- (void)updateCatalogFeedSettingCurrentAccount:(Account *)account
{
  [account loadAuthenticationDocumentUsingSignedInStateProvider:nil completion:^(BOOL success, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (success) {
        [AccountsManager shared].currentAccount = account;
        [self updateFeedAndRegistryOnAccountChange];
      } else {
        NSString *title = NSLocalizedString(@"Error Loading Library", @"Title for alert related to error loading library authentication doc");
        NSString *msg = NSLocalizedString(@"We can’t get your library right now. Please close and reopen the app to try again.", @"Message for alert related to error loading library authentication doc");
        msg = [msg stringByAppendingFormat:@" (%@: %ld)",
               NSLocalizedString(@"HTTP status", "Label for HTTP error code"),
               (long)error.httpStatusCode];
        UIAlertController *alert = [NYPLAlertUtils
                                    alertWithTitle:title
                                    message:msg];
        [self presentViewController:alert
                           animated:YES
                         completion:nil];
      }
    });
  }];
}
#endif

- (void)updateFeedAndRegistryOnAccountChange
{
  Account *account = [[AccountsManager sharedInstance] currentAccount];
  __block NSURL *mainFeedUrl = [NSURL URLWithString:account.catalogUrl];

  void (^completion)(void) = ^() {
    [[NYPLSettings sharedSettings] setAccountMainFeedURL:mainFeedUrl];
    [UIApplication sharedApplication].delegate.window.tintColor = [NYPLConfiguration mainColor];
    
    [[NYPLBookRegistry sharedRegistry] justLoad];
    [[NYPLBookRegistry sharedRegistry] syncResettingCache:NO completionHandler:^(NSDictionary *errorDict) {
      if (errorDict == nil) {
        [[NYPLBookRegistry sharedRegistry] save];
      }
    }];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:NSNotification.NYPLCurrentAccountDidChange
     object:nil];
  };

  NYPLUserAccount * const user = NYPLUserAccount.sharedAccount;
  if (user.defaultAuthDefinition.needsAgeCheck) {
    [[[AccountsManager shared] ageCheck] verifyCurrentAccountAgeRequirementWithUserAccountProvider:[NYPLUserAccount sharedAccount]
                                                                     currentLibraryAccountProvider:[AccountsManager shared]
                                                                                        completion:^(BOOL isOfAge)  {
      [NYPLMainThreadRun asyncIfNeeded: ^{
        mainFeedUrl = [user coppaURLWithIsOfAge:isOfAge];
        completion();
      }];
    }];
  } else if (user.catalogRequiresAuthentication && !user.hasCredentials) {
    // we're signed out, so sign in
    [NYPLAccountSignInViewController requestCredentialsWithCompletion:^{
      [NYPLMainThreadRun asyncIfNeeded:completion];
    }];
  } else {
    [NYPLMainThreadRun asyncIfNeeded:completion];
  }
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  NYPLSettings *settings = [NYPLSettings sharedSettings];
  if (settings.userHasSeenWelcomeScreen) {
    if (NYPLUserAccount.sharedAccount.defaultAuthDefinition.needsAgeCheck) {
      [[[AccountsManager shared] ageCheck] verifyCurrentAccountAgeRequirementWithUserAccountProvider:[NYPLUserAccount sharedAccount]
                                                                       currentLibraryAccountProvider:[AccountsManager shared]
                                                                                          completion:^(BOOL isOfAge) {
        dispatch_async(dispatch_get_main_queue(), ^{
          NSURL *mainFeedUrl = [NYPLUserAccount.sharedAccount coppaURLWithIsOfAge:isOfAge];
          [NYPLSettings.shared updateMainFeedURLIfNeededWithURL:mainFeedUrl];
        });
      }];
    } else {
      Account *account = [[AccountsManager sharedInstance] currentAccount];
      NSURL *accountFeedUrl = [NSURL URLWithString:account.catalogUrl];
      [NYPLSettings.shared updateMainFeedURLIfNeededWithURL:accountFeedUrl];
    }
  }
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
  if (UIAccessibilityIsVoiceOverRunning()) {
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
  }

#ifdef SIMPLYE
  [self presentWelcomeScreenIfNeeded];
#endif
}

#pragma mark -

- (void)syncBegan
{
  [NYPLMainThreadRun asyncIfNeeded:^{
    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.feedVC.navigationItem.leftBarButtonItem.enabled = NO;
  }];
}

- (void)syncEnded
{
  [NYPLMainThreadRun asyncIfNeeded:^{
    self.navigationItem.leftBarButtonItem.enabled = YES;
    self.feedVC.navigationItem.leftBarButtonItem.enabled = YES;
  }];
}

#ifdef SIMPLYE

- (void)presentWelcomeScreenIfNeeded
{
  NYPLSettings *settings = [NYPLSettings sharedSettings];

  if (settings.userHasSeenWelcomeScreen) {
    return;
  }

  if (NYPLUserAccount.sharedAccount.defaultAuthDefinition.needsAgeCheck) {
    NYPLUserAccount *userAccount = [NYPLUserAccount sharedAccount];
    [[[AccountsManager shared] ageCheck]
     verifyCurrentAccountAgeRequirementWithUserAccountProvider:userAccount
     currentLibraryAccountProvider:[AccountsManager shared]
     completion:^(BOOL isOfAge) {
      NSURL *mainFeedUrl = [userAccount coppaURLWithIsOfAge:isOfAge];
      [settings setAccountMainFeedURL:mainFeedUrl];
      [NYPLMainThreadRun asyncIfNeeded:^{
        [self presentWelcomeScreen];
      }];
    }];
  } else {
    Account *libAccount = [[AccountsManager sharedInstance] currentAccount];
    NSURL *mainFeedUrl = [NSURL URLWithString:libAccount.catalogUrl];
    [settings setAccountMainFeedURL:mainFeedUrl];
    [self presentWelcomeScreen];
  }
}

- (void)presentWelcomeScreen
{
  [UIApplication sharedApplication].delegate.window.tintColor = [NYPLConfiguration mainColor];

  NYPLWelcomeScreenViewController *welcomeVC = [[NYPLWelcomeScreenViewController alloc]
                                                initWithCompletion:^(Account *const account) {
    [self completeWelcomeScreenForLibraryAccount:account];
  }];

  UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:welcomeVC];

  if([[NYPLRootTabBarController sharedController] traitCollection].horizontalSizeClass != UIUserInterfaceSizeClassCompact) {
    [navController setModalPresentationStyle:UIModalPresentationFormSheet];
  } else {
    [navController setModalPresentationStyle:UIModalPresentationFullScreen];
  }
  [navController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];

  NYPLRootTabBarController *vc = [NYPLRootTabBarController sharedController];
  [vc safelyPresentViewController:navController animated:YES completion:nil];
}

- (void)completeWelcomeScreenForLibraryAccount:(Account *const)account
{
  [[NYPLSettings sharedSettings] setUserHasSeenWelcomeScreen:YES];
  [[NYPLBookRegistry sharedRegistry] save];
  [AccountsManager sharedInstance].currentAccount = account;
  [self dismissViewControllerAnimated:YES completion:^{
    [self updateFeedAndRegistryOnAccountChange];
  }];
}

#endif

@end
