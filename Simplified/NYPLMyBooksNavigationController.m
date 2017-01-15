#import "NYPLMyBooksViewController.h"

#import "NYPLMyBooksNavigationController.h"
#import "NYPLSettings.h"
#import "NYPLAccount.h"
#import "NYPLAlertController.h"
#import "NYPLBookRegistry.h"
#import "NYPLCatalogFeedViewController.h"
#import "NYPLConfiguration.h"
#import "NYPLRootTabBarController.h"
#import "NYPLCatalogNavigationController.h"
#import "NYPLSettingsPrimaryTableViewController.h"
#import "SimplyE-Swift.h"

#if defined(FEATURE_DRM_CONNECTOR)
#import <ADEPT/ADEPT.h>
#endif

@implementation NYPLMyBooksNavigationController

#pragma mark NSObject

- (instancetype)init
{
  NYPLMyBooksViewController *viewController =
  [[NYPLMyBooksViewController alloc] init];
  
  self = [super initWithRootViewController:viewController];
  if(!self) return nil;
  
  self.tabBarItem.image = [UIImage imageNamed:@"MyBooks"];
  
  
  viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                     initWithImage:[UIImage imageNamed:@"Catalog"] style:(UIBarButtonItemStylePlain)
                                                     target:self
                                                     action:@selector(switchLibrary)];
  viewController.navigationItem.leftBarButtonItem.accessibilityLabel = NSLocalizedString(@"AccessibilitySwitchLibrary", nil);
  viewController.navigationItem.leftBarButtonItem.enabled = YES;
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentAccountChanged) name:NYPLCurrentAccountDidChangeNotification object:nil];

  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
    
  NYPLMyBooksViewController *viewController = (NYPLMyBooksViewController *)self.visibleViewController;
  
  viewController.navigationItem.title = [[NYPLSettings sharedSettings] currentAccount].name;
    
}

- (void)currentAccountChanged
{
  [self popToRootViewControllerAnimated:NO];
}

- (void) switchLibrary
{
  NYPLMyBooksViewController *viewController = (NYPLMyBooksViewController *)self.visibleViewController;
  
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"PickYourLibrary", nil) message:nil preferredStyle:(UIAlertControllerStyleActionSheet)];
  alert.popoverPresentationController.barButtonItem = viewController.navigationItem.leftBarButtonItem;
  alert.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
  
  NSArray *accounts = [[NYPLSettings sharedSettings] settingsAccountsList];
  
  for (int i = 0; i < (int)accounts.count; i++) {
    Account *account = [[AccountsManager sharedInstance] account:[accounts[i] intValue]];
    [alert addAction:[UIAlertAction actionWithTitle:account.name style:(UIAlertActionStyleDefault) handler:^(__unused UIAlertAction *_Nonnull action) {
#if defined(FEATURE_DRM_CONNECTOR)
      if([NYPLADEPT sharedInstance].workflowsInProgress) {
        [self presentViewController:[NYPLAlertController
                                     alertWithTitle:@"PleaseWait"
                                     message:@"PleaseWaitMessage"]
                           animated:YES
                         completion:nil];
      } else {
        [[NYPLBookRegistry sharedRegistry] save];
        [[NYPLSettings sharedSettings] setCurrentAccountIdentifier:account.id];
        [self reloadSelected];
      }
#else
      [[NYPLBookRegistry sharedRegistry] save];
      [[NYPLSettings sharedSettings] setCurrentAccountIdentifier:account.id];
      [self reloadSelected];
#endif
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
  
  [[NYPLRootTabBarController sharedController] safelyPresentViewController:alert animated:YES completion:nil];
  
}

- (void) reloadSelected {
  
  [[NSNotificationCenter defaultCenter] postNotificationName:NYPLSyncBeganNotification object:nil];

  NYPLCatalogNavigationController * catalog = (NYPLCatalogNavigationController*)[NYPLRootTabBarController sharedController].viewControllers[0];
  [catalog reloadSelectedLibraryAccount];
  
  NYPLMyBooksViewController *viewController = (NYPLMyBooksViewController *)self.visibleViewController;
  viewController.navigationItem.title =  [[NYPLSettings sharedSettings] currentAccount].name;
//  viewController.navigationItem.leftBarButtonItem.enabled = NO;
//  [[NSNotificationCenter defaultCenter] postNotificationName:NYPLSyncBeganNotification object:nil];

}

@end
