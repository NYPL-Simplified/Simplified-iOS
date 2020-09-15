#import "NYPLMyBooksViewController.h"

#import "NYPLMyBooksNavigationController.h"
#import "NYPLBookRegistry.h"
#import "NYPLConfiguration.h"
#import "NYPLRootTabBarController.h"
#import "NYPLCatalogNavigationController.h"

#ifdef SIMPLYE
// TODO: SIMPLY-3053 this #ifdef can be removed once this ticket is done
#import "NYPLSettingsPrimaryTableViewController.h"
#endif

#import "SimplyE-Swift.h"

#if defined(FEATURE_DRM_CONNECTOR)
#import <ADEPT/ADEPT.h>
#endif

@implementation NYPLMyBooksNavigationController

#pragma mark NSObject

- (instancetype)init
{
  NYPLMyBooksViewController *vc = [[NYPLMyBooksViewController alloc] init];

  self = [super initWithRootViewController:vc];
  if(!self) return nil;
  
  self.tabBarItem.image = [UIImage imageNamed:@"MyBooks"];

#ifdef SIMPLYE
  vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                         initWithImage:[UIImage imageNamed:@"Catalog"]
                                         style:(UIBarButtonItemStylePlain)
                                         target:self
                                         action:@selector(switchLibrary)];
  vc.navigationItem.leftBarButtonItem.accessibilityLabel = NSLocalizedString(@"AccessibilitySwitchLibrary", nil);
  vc.navigationItem.leftBarButtonItem.enabled = YES;
#endif
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(currentAccountChanged)
                                               name:NSNotification.NYPLCurrentAccountDidChange
                                             object:nil];
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
  
  viewController.navigationItem.title = [AccountsManager shared].currentAccount.name;
    
}

- (void)currentAccountChanged
{
  if (![NSThread isMainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self popToRootViewControllerAnimated:NO];
    });
  } else {
    [self popToRootViewControllerAnimated:NO];
  }
}

#ifdef SIMPLYE
- (void) switchLibrary
{
  NYPLMyBooksViewController *viewController = (NYPLMyBooksViewController *)self.visibleViewController;

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

      BOOL workflowsInProgress = false;
    #if defined(FEATURE_DRM_CONNECTOR)
      workflowsInProgress = ([NYPLADEPT sharedInstance].workflowsInProgress || [NYPLBookRegistry sharedRegistry].syncing == YES);
    #else
      workflowsInProgress = ([NYPLBookRegistry sharedRegistry].syncing == YES);
    #endif

      if(workflowsInProgress) {
        [self presentViewController:[NYPLAlertUtils
                                     alertWithTitle:@"PleaseWait"
                                     message:@"PleaseWaitMessage"]
                           animated:YES
                         completion:nil];
      } else {
        [[NYPLBookRegistry sharedRegistry] save];
        [AccountsManager shared].currentAccount = account;
        [self reloadSelected];
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
  
  [[NYPLRootTabBarController sharedController] safelyPresentViewController:alert animated:YES completion:nil];
  
}
#endif

- (void)reloadSelected
{
  NYPLCatalogNavigationController * catalog = (NYPLCatalogNavigationController*)[NYPLRootTabBarController sharedController].viewControllers[0];
  [catalog updateFeedAndRegistryOnAccountChange];
  
  NYPLMyBooksViewController *viewController = (NYPLMyBooksViewController *)self.visibleViewController;
  viewController.navigationItem.title =  [AccountsManager shared].currentAccount.name;
}

@end
