#import "SimplyE-Swift.h"
#import "NYPLCatalogFeedViewController.h"
#import "NYPLConfiguration.h"
#import "NYPLCatalogNavigationController.h"
#import "NYPLAccountSignInViewController.h"
#import "NYPLBookRegistry.h"
#import "NYPLRootTabBarController.h"
#import "NSString+NYPLStringAdditions.h"

@interface NYPLCatalogNavigationController()

@property (nonatomic) NYPLCatalogFeedViewController *const viewController;

@end


@implementation NYPLCatalogNavigationController

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
  // unfortunately it is possible to get here with a nil feed URL. This is
  // the result of an early initialization of the navigation controller
  // while the account is not yet set up. While this is definitely not
  // ideal, in my observations this seems to always be followed by
  // another `load` command once the authentication document is received.
  NSURL *urlToLoad = [NYPLSettings sharedSettings].accountMainFeedURL;
  self.viewController = [[NYPLCatalogFeedViewController alloc]
                         initWithURL:urlToLoad];
  
  self.viewController.title = NSLocalizedString(@"Catalog", nil);

#ifdef SIMPLYE
  self.viewController.navigationItem.title = [AccountsManager shared].currentAccount.name;
  [self setNavigationLeftBarButtonForVC:self.viewController];
#endif

  self.viewController.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Catalog", nil) style:UIBarButtonItemStylePlain target:nil action:nil];

  self.viewControllers = @[self.viewController];
}

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  
  self.tabBarItem.title = NSLocalizedString(@"Catalog", nil);
  self.tabBarItem.image = [UIImage imageNamed:@"Catalog"];
  
  [self loadTopLevelCatalogViewController];
  
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

- (void)currentAccountChanged
{
  [self loadTopLevelCatalogViewController];
}

- (void)syncBegan
{
  self.navigationItem.leftBarButtonItem.enabled = NO;
  self.viewController.navigationItem.leftBarButtonItem.enabled = NO;
}

- (void)syncEnded
{
  self.navigationItem.leftBarButtonItem.enabled = YES;
  self.viewController.navigationItem.leftBarButtonItem.enabled = YES;
}

#ifdef SIMPLYE
- (void)updateCatalogFeedSettingCurrentAccount:(Account *)account
{
  [account loadAuthenticationDocumentUsingSignedInStateProvider:nil completion:^(BOOL success) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (success) {
        [AccountsManager shared].currentAccount = account;
        [self updateFeedAndRegistryOnAccountChange];
      } else {
        NSString *title = NSLocalizedString(@"Error Loading Library", @"Title for alert related to error loading library authentication doc");
        NSString *msg = NSLocalizedString(@"LibraryLoadError", @"Message for alert related to error loading library authentication doc");
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
    [[NYPLBookRegistry sharedRegistry] syncResettingCache:NO completionHandler:^(BOOL success) {
      if (success) {
        [[NYPLBookRegistry sharedRegistry] save];
      }
    }];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:NSNotification.NYPLCurrentAccountDidChange
     object:nil];
  };
  if (NYPLUserAccount.sharedAccount.authDefinition.needsAgeCheck) {
    [[NYPLAgeCheck shared] verifyCurrentAccountAgeRequirement:^(BOOL isOfAge) {
      dispatch_async(dispatch_get_main_queue(), ^{
        mainFeedUrl = [NYPLUserAccount.sharedAccount.authDefinition coppaURLWithIsOfAge:isOfAge];
        completion();
      });
    }];
  } else if (NYPLUserAccount.sharedAccount.isCatalogSecured && !NYPLUserAccount.sharedAccount.hasCredentials) {
    // sign in
    [NYPLAccountSignInViewController requestCredentialsUsingExistingBarcode:NO authorizeImmediately:YES completionHandler:^{
      dispatch_async(dispatch_get_main_queue(), ^{
        completion();
      });
    }];
  } else {
    if (![NSThread isMainThread]) {
      dispatch_async(dispatch_get_main_queue(), ^{
        completion();
      });
    } else {
      completion();
    }
  }
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  NYPLSettings *settings = [NYPLSettings sharedSettings];
  if (settings.userHasSeenWelcomeScreen == YES) {
    Account *account = [[AccountsManager sharedInstance] currentAccount];

    __block NSURL *mainFeedUrl = [NSURL URLWithString:account.catalogUrl];
    void (^completion)(void) = ^() {
      [[NYPLSettings sharedSettings] setAccountMainFeedURL:mainFeedUrl];
      [UIApplication sharedApplication].delegate.window.tintColor = [NYPLConfiguration mainColor];
      // TODO: SIMPLY-2862 should this be posted only if actually different?
      [[NSNotificationCenter defaultCenter]
      postNotificationName:NSNotification.NYPLCurrentAccountDidChange
      object:nil];
    };

    if (NYPLUserAccount.sharedAccount.authDefinition.needsAgeCheck) {
      [[NYPLAgeCheck shared] verifyCurrentAccountAgeRequirement:^(BOOL isOfAge) {
        dispatch_async(dispatch_get_main_queue(), ^{
          mainFeedUrl = [NYPLUserAccount.sharedAccount.authDefinition coppaURLWithIsOfAge:isOfAge];
          completion();
        });
      }];
    } else {
      completion();
    }
  }
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
  if (UIAccessibilityIsVoiceOverRunning()) {
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
  }

  // TODO: SIMPLY-3048 refactor better in a extension
#ifdef SIMPLYE
  NYPLSettings *settings = [NYPLSettings sharedSettings];
  
  if (settings.userHasSeenWelcomeScreen == NO) {
    Account *currentAccount = [[AccountsManager sharedInstance] currentAccount];

    __block NSURL *mainFeedUrl = [NSURL URLWithString:currentAccount.catalogUrl];
    void (^completion)(void) = ^() {
      [[NYPLSettings sharedSettings] setAccountMainFeedURL:mainFeedUrl];
      [UIApplication sharedApplication].delegate.window.tintColor = [NYPLConfiguration mainColor];
      
      NYPLWelcomeScreenViewController *welcomeScreenVC = [[NYPLWelcomeScreenViewController alloc] initWithCompletion:^(Account *const account) {
        if (![NSThread isMainThread]) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [self welcomeScreenCompletionHandlerForAccount:account];
          });
        } else {
          [self welcomeScreenCompletionHandlerForAccount:account];
        }
      }];

      UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:welcomeScreenVC];

      if([[NYPLRootTabBarController sharedController] traitCollection].horizontalSizeClass != UIUserInterfaceSizeClassCompact) {
        [navController setModalPresentationStyle:UIModalPresentationFormSheet];
      } else {
        [navController setModalPresentationStyle:UIModalPresentationFullScreen];
      }
      [navController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];

      NYPLRootTabBarController *vc = [NYPLRootTabBarController sharedController];
      [vc safelyPresentViewController:navController animated:YES completion:nil];
    };
    if (NYPLUserAccount.sharedAccount.authDefinition.needsAgeCheck) {
      [[NYPLAgeCheck shared] verifyCurrentAccountAgeRequirement:^(BOOL isOfAge) {
        mainFeedUrl = [NYPLUserAccount.sharedAccount.authDefinition coppaURLWithIsOfAge:isOfAge];
        completion();
      }];
    } else {
      completion();
    }
  }
#endif
}

-(void) welcomeScreenCompletionHandlerForAccount:(Account *const)account
{
  [[NYPLSettings sharedSettings] setUserHasSeenWelcomeScreen:YES];
  [[NYPLBookRegistry sharedRegistry] save];
  [AccountsManager sharedInstance].currentAccount = account;
  [self dismissViewControllerAnimated:YES completion:^{
    [self updateFeedAndRegistryOnAccountChange];
  }];
//  [self updateFeedAndRegistryOnAccountChange];
//  [self dismissViewControllerAnimated:YES completion:nil];
}

@end
