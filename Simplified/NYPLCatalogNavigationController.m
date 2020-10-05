#import "NYPLCatalogFeedViewController.h"
#import "NYPLConfiguration.h"

#import "NYPLCatalogNavigationController.h"

#import "NYPLAccountSignInViewController.h"
#import "NYPLBookRegistry.h"
#import "NYPLRootTabBarController.h"
#import "NYPLMyBooksNavigationController.h"
#import "NYPLMyBooksViewController.h"
#import "NYPLHoldsNavigationController.h"
#ifdef SIMPLYE
// TODO: SIMPLY-3053 this #ifdef can be removed once this ticket is done
#import "NYPLSettingsPrimaryTableViewController.h"
#endif
#import "SimplyE-Swift.h"
#import "NYPLAppDelegate.h"
#import "NSString+NYPLStringAdditions.h"

#if defined(FEATURE_DRM_CONNECTOR)
#import <ADEPT/ADEPT.h>
#endif

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
  
  // The top-level view controller uses the same image used for the tab bar in place of the usual
  // title text.
  self.viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                          initWithImage:[UIImage imageNamed:@"Catalog"] style:(UIBarButtonItemStylePlain)
                                                          target:self
                                                          action:@selector(switchLibrary)];
  self.viewController.navigationItem.leftBarButtonItem.accessibilityLabel = NSLocalizedString(@"AccessibilitySwitchLibrary", nil);
  
  self.viewController.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Catalog", nil) style:UIBarButtonItemStylePlain target:nil action:nil];
#endif

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
- (void)switchLibrary
{
  NYPLCatalogFeedViewController *viewController = (NYPLCatalogFeedViewController *)self.visibleViewController;

  UIAlertControllerStyle style;
  if (viewController && viewController.navigationItem.leftBarButtonItem) {
    style = UIAlertControllerStyleActionSheet;
  } else {
    style = UIAlertControllerStyleAlert;
  }

  UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"PickYourLibrary", nil) message:nil preferredStyle:style];
  alert.popoverPresentationController.barButtonItem = viewController.navigationItem.leftBarButtonItem;
  alert.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
  
  NSArray *accounts = [[NYPLSettings sharedSettings] settingsAccountsList];
  
  for (int i = 0; i < (int)accounts.count; i++) {
    Account *account = [[AccountsManager sharedInstance] account:accounts[i]];
    if (!account) {
      continue;
    }

    [alert addAction:[UIAlertAction actionWithTitle:account.name style:(UIAlertActionStyleDefault) handler:^(__unused UIAlertAction *_Nonnull action) {

      BOOL workflowsInProgress;
    #if defined(FEATURE_DRM_CONNECTOR)
      workflowsInProgress = ([NYPLADEPT sharedInstance].workflowsInProgress || [NYPLBookRegistry sharedRegistry].syncing == YES);
    #else
      workflowsInProgress = ([NYPLBookRegistry sharedRegistry].syncing == YES);
    #endif

      if (workflowsInProgress) {
        UIAlertController *alert = [NYPLAlertUtils
                                    alertWithTitle:@"PleaseWait"
                                    message:@"PleaseWaitMessage"];
        [self presentViewController:alert
                           animated:YES
                         completion:nil];
      } else {
        [[NYPLBookRegistry sharedRegistry] save];
        [account loadAuthenticationDocumentUsingSignedInStateProvider:nil completion:^(BOOL success) {
          dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
              [AccountsManager shared].currentAccount = account;
              [self updateFeedAndRegistryOnAccountChange];
            } else {
              UIAlertController *alert = [NYPLAlertUtils
                                          alertWithTitle:@""
                                          message:@"LibraryLoadError"];
              [self presentViewController:alert
                                 animated:YES
                               completion:nil];
            }
          });
        }];
      }
    }]];
  }
  
  [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ManageAccounts", nil) style:(UIAlertActionStyleDefault) handler:^(__unused UIAlertAction *_Nonnull action) {
    NSUInteger tabCount = [[[NYPLRootTabBarController sharedController] viewControllers] count];
    UISplitViewController *splitViewVC = [[[NYPLRootTabBarController sharedController] viewControllers] lastObject];
    UINavigationController *masterNavVC = [[splitViewVC viewControllers] firstObject];
    [masterNavVC popToRootViewControllerAnimated:NO];
    [[NYPLRootTabBarController sharedController] setSelectedIndex:tabCount-1];
    NYPLSettingsPrimaryTableViewController *tableVC = [[masterNavVC viewControllers] firstObject];
    [tableVC.delegate settingsPrimaryTableViewController:tableVC didSelectItem:NYPLSettingsPrimaryTableViewControllerItemAccount];
  }]];

  [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:(UIAlertActionStyleCancel) handler:nil]];

  [[NYPLRootTabBarController sharedController]
   safelyPresentViewController:alert
   animated:YES
   completion:nil];
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
