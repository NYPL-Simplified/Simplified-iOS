#import "NYPLCatalogFeedViewController.h"
#import "NYPLConfiguration.h"

#import "NYPLCatalogNavigationController.h"
#import "NYPLSettings.h"
#import "NYPLAccount.h"
#import "NYPLBookRegistry.h"
#import "NYPLRootTabBarController.h"
#import "NYPLMyBooksNavigationController.h"
#import "NYPLMyBooksViewController.h"
#import "NYPLHoldsNavigationController.h"
#import "NYPLSettingsPrimaryTableViewController.h"
#import "SimplyE-Swift.h"
#import "NYPLAppDelegate.h"
#import "NSString+NYPLStringAdditions.h"
#import "NYPLAlertController.h"

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
  self.viewController = [[NYPLCatalogFeedViewController alloc]
                         initWithURL:[NYPLSettings sharedSettings].accountMainFeedURL];
  
  self.viewController.title = NSLocalizedString(@"Catalog", nil);
  self.viewController.navigationItem.title = [AccountsManager shared].currentAccount.name;
  
  // The top-level view controller uses the same image used for the tab bar in place of the usual
  // title text.
  self.viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                          initWithImage:[UIImage imageNamed:@"Catalog"] style:(UIBarButtonItemStylePlain)
                                                          target:self
                                                          action:@selector(switchLibrary)];
  self.viewController.navigationItem.leftBarButtonItem.accessibilityLabel = NSLocalizedString(@"AccessibilitySwitchLibrary", nil);
  
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
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentAccountChanged) name:NYPLCurrentAccountDidChangeNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncBegan) name:NYPLSyncBeganNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncEnded) name:NYPLSyncEndedNotification object:nil];
  
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

- (void)switchLibrary
{
  NYPLCatalogFeedViewController *viewController = (NYPLCatalogFeedViewController *)self.visibleViewController;

  UIAlertControllerStyle style;
  if (viewController) {
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

      if(workflowsInProgress) {
        [self presentViewController:[NYPLAlertController
                                     alertWithTitle:@"PleaseWait"
                                     message:@"PleaseWaitMessage"]
                           animated:YES
                         completion:nil];
      } else {
        [[NYPLBookRegistry sharedRegistry] save];
        [AccountsManager shared].currentAccount = account;
        [self updateFeedAndRegistryOnAccountChange];
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


- (void)updateFeedAndRegistryOnAccountChange
{
  Account *account = [[AccountsManager sharedInstance] currentAccount];
  [[NYPLSettings sharedSettings] setAccountMainFeedURL:[NSURL URLWithString:account.catalogUrl]];
  [UIApplication sharedApplication].delegate.window.tintColor = [NYPLConfiguration mainColor];

  [[NYPLBookRegistry sharedRegistry] justLoad];
  [[NYPLBookRegistry sharedRegistry] syncWithCompletionHandler:^(BOOL __unused success) {
    if (success) {
      [[NYPLBookRegistry sharedRegistry] save];
    }
  }];

  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLCurrentAccountDidChangeNotification
   object:nil];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  NYPLSettings *settings = [NYPLSettings sharedSettings];
  if (settings.userHasSeenWelcomeScreen == YES) {
    Account *account = [[AccountsManager sharedInstance] currentAccount];
    [[NYPLSettings sharedSettings] setAccountMainFeedURL:[NSURL URLWithString:account.catalogUrl]];
    [UIApplication sharedApplication].delegate.window.tintColor = [NYPLConfiguration mainColor];

    [[NSNotificationCenter defaultCenter]
     postNotificationName:NYPLCurrentAccountDidChangeNotification
     object:nil];
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
    [[NYPLSettings sharedSettings] setAccountMainFeedURL:[NSURL URLWithString:currentAccount.catalogUrl]];
    [UIApplication sharedApplication].delegate.window.tintColor = [NYPLConfiguration mainColor];
    
    NYPLWelcomeScreenViewController *welcomeScreenVC = [[NYPLWelcomeScreenViewController alloc] initWithCompletion:^(Account *const account) {
      [[NYPLSettings sharedSettings] setUserHasSeenWelcomeScreen:YES];
      [[NYPLBookRegistry sharedRegistry] save];
      [AccountsManager sharedInstance].currentAccount = account;
      [self updateFeedAndRegistryOnAccountChange];
      [self dismissViewControllerAnimated:YES completion:nil];
    }];

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:welcomeScreenVC];

    if([[NYPLRootTabBarController sharedController] traitCollection].horizontalSizeClass != UIUserInterfaceSizeClassCompact) {
      [navController setModalPresentationStyle:UIModalPresentationFormSheet];
    }
    [navController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];

    NYPLRootTabBarController *vc = [NYPLRootTabBarController sharedController];
    [vc safelyPresentViewController:navController animated:YES completion:nil];
  }
}

@end
