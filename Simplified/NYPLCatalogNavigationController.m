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
                                                     initWithImage:[UIImage imageNamed:@"Catalog"] style:(UIBarButtonItemStylePlain)
                                                     target:self
                                                     action:@selector(switchLibrary)];
  viewController.navigationItem.leftBarButtonItem.enabled = YES;
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentAccountChanged) name:NYPLCurrentAccountDidChangeNotification object:nil];
  
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)currentAccountChanged
{
  [self popToRootViewControllerAnimated:NO];
}

- (void)deactivateDevice
{
  Account *account = [[AccountsManager sharedInstance] currentAccount];
  
  if (account.needsAuth && [[NYPLAccount sharedAccount:account.id] hasBarcodeAndPIN] && [[NYPLAccount sharedAccount:account.id] hasLicensor])
  {
    NSMutableArray* foo = [[[[NYPLAccount sharedAccount:account.id] licensor][@"clientToken"]  stringByReplacingOccurrencesOfString:@"\n" withString:@""] componentsSeparatedByString: @"|"].mutableCopy;

    NSString *last = foo.lastObject;
    [foo removeLastObject];
    NSString *first = [foo componentsJoinedByString:@"|"];
    
    NYPLLOG([[NYPLAccount sharedAccount:account.id] licensor]);
    NYPLLOG(first);
    NYPLLOG(last);
    
    [[NYPLADEPT sharedInstance]
     deauthorizeWithUsername:first
     password:last
     userID:[[NYPLAccount sharedAccount:account.id] userID] deviceID:[[NYPLAccount sharedAccount:account.id] deviceID]
     completion:^(BOOL success, __unused NSError *error) {
       if(!success) {
         // Even though we failed, all we do is log the error. The reason is
         // that we want the user to be able to log out anyway because the
         // failure is probably due to bad credentials and we do not want the
         // user to have to change their barcode or PIN just to log out. This
         // is only a temporary measure and we'll switch to deauthorizing with
         // a token that will remain invalid indefinitely in the near future.
         NYPLLOG(@"Failed to deauthorize successfully.");
       }
       
       [[UIApplication sharedApplication] endIgnoringInteractionEvents];
       
     }];
  }

}
- (void)switchLibrary
{
  
  
  NYPLCatalogFeedViewController *viewController = (NYPLCatalogFeedViewController *)self.visibleViewController;

  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Pick Your Library" message:nil preferredStyle:(UIAlertControllerStyleActionSheet)];
  alert.popoverPresentationController.barButtonItem = viewController.navigationItem.leftBarButtonItem;
  alert.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
  
  NSArray *accounts = [[NYPLSettings sharedSettings] settingsAccountsList];
  
  for (int i = 0; i < (int)accounts.count; i++) {
    Account *account = [[AccountsManager sharedInstance] account:[accounts[i] intValue]];
    [alert addAction:[UIAlertAction actionWithTitle:account.name style:(UIAlertActionStyleDefault) handler:^(__unused UIAlertAction *_Nonnull action) {
      [[NYPLBookRegistry sharedRegistry] save];
      [[NYPLSettings sharedSettings] setCurrentAccountIdentifier:account.id];
      [self reloadSelectedLibraryAccount];
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


- (void) reloadSelectedLibraryAccount {
  
  Account *account = [[AccountsManager sharedInstance] currentAccount];
  
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
  
  
  if (account.needsAuth
      && [[NYPLAccount sharedAccount:account.id] hasBarcodeAndPIN]
      && [[NYPLAccount sharedAccount:account.id] hasLicensor])
  {
    NSMutableArray* foo = [[[[NYPLAccount sharedAccount:account.id] licensor][@"clientToken"]
                            stringByReplacingOccurrencesOfString:@"\n" withString:@""]
                           componentsSeparatedByString: @"|"].mutableCopy;

    NSString *last = foo.lastObject;
    [foo removeLastObject];
    NSString *first = [foo componentsJoinedByString:@"|"];
    
    NYPLLOG([[NYPLAccount sharedAccount:account.id] licensor]);
    NYPLLOG(first);
    NYPLLOG(last);
    
    [[NYPLADEPT sharedInstance]
     authorizeWithVendorID:[[NYPLAccount sharedAccount:account.id] licensor][@"vendor"]
     username:first
     password:last
     completion:^(BOOL success, NSError *error, NSString *deviceID, NSString *userID) {
       
       NYPLLOG(error);
       
       if (success)
       {
         [[NYPLAccount sharedAccount:account.id] setUserID:userID];
         [[NYPLAccount sharedAccount:account.id] setDeviceID:deviceID];
         [[NYPLBookRegistry sharedRegistry] syncWithCompletionHandler:nil];
       }
       else{
         
         
         // show alert Temporary, needs to be replaced or removed.
         
         
//         NYPLAlertController *alertCont = [NYPLAlertController
//                                           alertControllerWithTitle:NSLocalizedString(@"Error", nil)
//                                           message:error.userInfo[@"originalCode"]
//                                           preferredStyle:UIAlertControllerStyleAlert];
//         
//         [alertCont addAction: [UIAlertAction actionWithTitle:@"OK"
//                                                        style:UIAlertActionStyleDefault
//                                                      handler:nil]];
//         
//         
//         [alertCont presentFromViewControllerOrNil:nil animated:YES completion:nil];

         
       }
      
       
     }];
  }
  else if (account.needsAuth)
  {
    [[NYPLBookRegistry sharedRegistry] syncWithCompletionHandler:nil];
  }
  
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
  NYPLCatalogFeedViewController *viewController = (NYPLCatalogFeedViewController *)self.visibleViewController;
  viewController.navigationItem.title = [[NYPLSettings sharedSettings] currentAccount].name;

 
  if (UIAccessibilityIsVoiceOverRunning()) {
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
  }
  
  NYPLSettings *settings = [NYPLSettings sharedSettings];
  
  if (settings.userHasSeenWelcomeScreen == NO) {
    
    if (settings.acceptedEULABeforeMultiLibrary == YES) {
      Account *nyplAccount = [[AccountsManager sharedInstance] account:0];
      nyplAccount.eulaIsAccepted = YES;
    }
    
    [self reloadSelectedLibraryAccount];
    
    NYPLWelcomeScreenViewController *welcomeScreenVC = [[NYPLWelcomeScreenViewController alloc] initWithCompletion:^(NSInteger accountID) {
     
      [[NYPLBookRegistry sharedRegistry] save];
      [[NYPLSettings sharedSettings] setCurrentAccountIdentifier:accountID];
      [self reloadSelectedLibraryAccount];
      [[NYPLSettings sharedSettings] setUserHasSeenWelcomeScreen:YES];
      [self dismissViewControllerAnimated:YES completion:nil];
      
    }];
  
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:welcomeScreenVC];
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
      [navController setModalPresentationStyle:UIModalPresentationFormSheet];
    }
    [navController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    
    NYPLRootTabBarController *vc = [NYPLRootTabBarController sharedController];
    [vc safelyPresentViewController:navController animated:YES completion:nil];
  }
}

@end
