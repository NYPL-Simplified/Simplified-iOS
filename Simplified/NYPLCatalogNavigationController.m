#import "NYPLCatalogFeedViewController.h"
#import "NYPLConfiguration.h"

#import "NYPLCatalogNavigationController.h"
#import "NYPLSettings.h"
#import "NYPLAccount.h"
#import "NYPLBookRegistry.h"
#import "NYPLRootTabBarController.h"
#import "NYPLMyBooksNavigationController.h"
#import "NYPLMyBooksViewController.h"
#import "NYPLSettingsPrimaryTableViewController.h"
#import "SimplyE-Swift.h"
#import "NYPLAppDelegate.h"

@implementation NYPLCatalogNavigationController

#pragma mark NSObject

- (instancetype)init
{
  NYPLCatalogFeedViewController *const viewController =
    [[NYPLCatalogFeedViewController alloc]
     initWithURL:[NYPLConfiguration mainFeedURL]];
  
  viewController.title = NSLocalizedString(@"Catalog", nil);
  
  self = [super initWithRootViewController:viewController];
  if(!self) return nil;
  
  self.tabBarItem.image = [UIImage imageNamed:@"Catalog"];
  
  // The top-level view controller uses the same image used for the tab bar in place of the usual
  // title text.

  viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                     initWithImage:[UIImage imageNamed:@"lib-icon"] style:(UIBarButtonItemStylePlain)
                                                     
                                                     target:self
                                                     action:@selector(switchLibrary)];
  viewController.navigationItem.leftBarButtonItem.enabled = YES;
  
  
  return self;
}
-(void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  NYPLCatalogFeedViewController *viewController = (NYPLCatalogFeedViewController *)self.visibleViewController;
  viewController.navigationItem.title = [[NYPLSettings sharedSettings] currentAccount].name;

}


- (void) switchLibrary
{
  NYPLCatalogFeedViewController *viewController = (NYPLCatalogFeedViewController *)self.visibleViewController;

  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Pick Your Library" message:nil preferredStyle:(UIAlertControllerStyleActionSheet)];
  alert.popoverPresentationController.barButtonItem = viewController.navigationItem.leftBarButtonItem;
  alert.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
  
  NSArray *accounts = [[NYPLSettings sharedSettings] settingsAccountsList];
  
  for (int i = 0; i < (int)accounts.count; i++) {
    Account *account = [[AccountsManager sharedInstance] account:[accounts[i] intValue]];
    [alert addAction:[UIAlertAction actionWithTitle:account.name style:(UIAlertActionStyleDefault) handler:^(__unused UIAlertAction *_Nonnull action) {
      [[NYPLSettings sharedSettings] setCurrentAccountIdentifier:account.id];
      [self reloadSelected];
    }]];
  }
  
  [alert addAction:[UIAlertAction actionWithTitle:@"Manage Accounts" style:(UIAlertActionStyleDefault) handler:^(__unused UIAlertAction *_Nonnull action) {
    NSUInteger tabCount = [[[NYPLRootTabBarController sharedController] viewControllers] count];
    UISplitViewController *splitViewVC = [[[NYPLRootTabBarController sharedController] viewControllers] lastObject];
    UINavigationController *masterNavVC = [[splitViewVC viewControllers] firstObject];
    [masterNavVC popToRootViewControllerAnimated:NO];
    [[NYPLRootTabBarController sharedController] setSelectedIndex:tabCount-1];
    NYPLSettingsPrimaryTableViewController *tableVC = [[masterNavVC viewControllers] firstObject];
    [tableVC.delegate settingsPrimaryTableViewController:tableVC didSelectItem:NYPLSettingsPrimaryTableViewControllerItemAccount];
  }]];

  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:(UIAlertActionStyleCancel) handler:nil]];

  [[NYPLRootTabBarController sharedController]
   safelyPresentViewController:alert
   animated:YES
   completion:nil];
}


- (void) reloadSelected {
  
  Account *account = [[NYPLSettings sharedSettings] currentAccount];
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLAccountDidChangeNotification
   object:nil];
  
  [[NYPLSettings sharedSettings] setAccountMainFeedURL:[NSURL URLWithString:account.catalogUrl]];
  [UIApplication sharedApplication].delegate.window.tintColor = [NYPLConfiguration mainColor];
  
  [[NYPLBookRegistry sharedRegistry] justLoad];

  if ([[self.visibleViewController class] isSubclassOfClass:[NYPLCatalogFeedViewController class]] &&
       [self.visibleViewController respondsToSelector:@selector(load)]) {
    NYPLCatalogFeedViewController *viewController = (NYPLCatalogFeedViewController *)self.visibleViewController;
    viewController.URL = [NYPLConfiguration mainFeedURL]; // It may have changed
    [viewController load];
    viewController.navigationItem.title = [[NYPLSettings sharedSettings] currentAccount].name;
  } else if ([[self.topViewController class] isSubclassOfClass:[NYPLCatalogFeedViewController class]] &&
             [self.topViewController respondsToSelector:@selector(load)]) {
    NYPLCatalogFeedViewController *viewController = (NYPLCatalogFeedViewController *)self.topViewController;
    viewController.URL = [NYPLConfiguration mainFeedURL]; // It may have changed
    [viewController load];
    viewController.navigationItem.title = [[NYPLSettings sharedSettings] currentAccount].name;
  }
}

- (void) viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
  if (UIAccessibilityIsVoiceOverRunning()) {
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
  }
  
  if ([[NYPLSettings sharedSettings] userPresentedWelcomeScreen] == NO) {
    NYPLWelcomeScreenViewController *welcomeScreenVC = [[NYPLWelcomeScreenViewController alloc] initWithCompletion:^() {
        [self reloadSelected];
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:welcomeScreenVC];
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
      [navController setModalPresentationStyle:UIModalPresentationFormSheet];
    }
    NYPLRootTabBarController *vc = [NYPLRootTabBarController sharedController];
    [vc safelyPresentViewController:navController animated:YES completion:nil];
    [[NYPLSettings sharedSettings] setUserPresentedWelcomeScreen:YES];
  }
}

@end
