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

#pragma mark NSObject

- (instancetype)init
{
  self.viewController =
  [[NYPLCatalogFeedViewController alloc]
   initWithURL:[NYPLConfiguration mainFeedURL]];
  
  self.viewController.title = NSLocalizedString(@"Catalog", nil);
  
  self = [super initWithRootViewController:self.viewController];
  if(!self) return nil;
  
  self.tabBarItem.image = [UIImage imageNamed:@"Catalog"];
  
  // The top-level view controller uses the same image used for the tab bar in place of the usual
  // title text.
  
  self.viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                          initWithImage:[UIImage imageNamed:@"Catalog"] style:(UIBarButtonItemStylePlain)
                                                          target:self
                                                          action:@selector(switchLibrary)];
  self.viewController.navigationItem.leftBarButtonItem.accessibilityLabel = NSLocalizedString(@"AccessibilitySwitchLibrary", nil);
  self.viewController.navigationItem.leftBarButtonItem.enabled = YES;
  
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
  [self popToRootViewControllerAnimated:NO];
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
                                     alertWithTitle:@"SettingsAccountViewControllerCannotLogOutTitle"
                                     message:@"SettingsAccountViewControllerCannotLogOutMessage"]
                           animated:YES
                         completion:nil];
      } else {
        [[NYPLBookRegistry sharedRegistry] save];
        [[NYPLSettings sharedSettings] setCurrentAccountIdentifier:account.id];
        [self reloadSelectedLibraryAccount];
      }
#else
      [[NYPLBookRegistry sharedRegistry] save];
      [[NYPLSettings sharedSettings] setCurrentAccountIdentifier:account.id];
      [self reloadSelectedLibraryAccount];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:NYPLSyncBeganNotification object:nil];

    viewController.navigationItem.title = [[NYPLSettings sharedSettings] currentAccount].name;
  } else if ([[self.topViewController class] isSubclassOfClass:[NYPLCatalogFeedViewController class]] &&
             [self.topViewController respondsToSelector:@selector(load)]) {
    NYPLCatalogFeedViewController *viewController = (NYPLCatalogFeedViewController *)self.topViewController;
    viewController.URL = [NYPLConfiguration mainFeedURL]; // It may have changed
    [viewController load];
    [[NSNotificationCenter defaultCenter] postNotificationName:NYPLSyncBeganNotification object:nil];

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
#if defined(FEATURE_DRM_CONNECTOR)

    [[NYPLADEPT sharedInstance]
     authorizeWithVendorID:[[NYPLAccount sharedAccount:account.id] licensor][@"vendor"]
     username:first
     password:last
     userID:[[NYPLAccount sharedAccount:account.id] userID] deviceID:[[NYPLAccount sharedAccount:account.id] deviceID]
     completion:^(BOOL success, NSError *error, NSString *deviceID, NSString *userID) {
       
       NYPLLOG(error);
       
       if (success)
       {
         [[NYPLAccount sharedAccount:account.id] setUserID:userID];
         [[NYPLAccount sharedAccount:account.id] setDeviceID:deviceID];

         [[NYPLBookRegistry sharedRegistry] syncWithCompletionHandler:^(BOOL __unused success) {
           [[NSNotificationCenter defaultCenter] postNotificationName:NYPLSyncEndedNotification object:nil];
         }];
         
         // POST deviceID to adobeDevicesLink
         NSURL *deviceManager =  [NSURL URLWithString: [[NYPLAccount sharedAccount:account.id] licensor][@"deviceManager"]];
         if (deviceManager != nil) {
           [NYPLDeviceManager postDevice:deviceID url:deviceManager];
         }
       }
       else
       {
         [[NSNotificationCenter defaultCenter] postNotificationName:NYPLSyncEndedNotification object:nil];
       }
     }];
#endif

  }
  else{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      [[NSNotificationCenter defaultCenter] postNotificationName:NYPLSyncEndedNotification object:nil];
    }];
  }
  
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  NYPLSettings *settings = [NYPLSettings sharedSettings];
  
  if (settings.userHasSeenWelcomeScreen == YES) {
    [self reloadSelectedLibraryAccount];
  }
  
}
- (void)checkSyncSetting
{
  [NYPLAnnotations syncSettingsWithCompletionHandler:^(BOOL exist) {
    
    if (!exist)
    {
      // alert
      
      Account *account = [[AccountsManager sharedInstance] currentAccount];
      
      NSString *title = @"SimplyE Sync";
      NSString *message = @"<Initial setup> Synchronize your bookmarks and last reading position across all your SimplyE devices.";
      
      
      NYPLAlertController *alertController = [NYPLAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
      
      
      [alertController addAction:[UIAlertAction actionWithTitle:@"Do not Enable Sync" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction * _Nonnull action) {
        
        // add server update here as well
        [NYPLAnnotations updateSyncSettings:false];
        account.syncIsEnabled = NO;
        
      }]];
      
      
      [alertController addAction:[UIAlertAction actionWithTitle:@"Enable Sync" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction * _Nonnull action) {
        
        // add server update here as well
        
        [NYPLAnnotations updateSyncSettings:true];
        account.syncIsEnabled = YES;
        
      }]];
      
      
      
      [[NYPLRootTabBarController sharedController] safelyPresentViewController:alertController
                                                                      animated:YES completion:nil];
      
    }
    
  }];
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
  
  
  [self checkSyncSetting];
  
  if (settings.userHasSeenWelcomeScreen == NO) {
    
    if (settings.acceptedEULABeforeMultiLibrary == YES) {
      Account *nyplAccount = [[AccountsManager sharedInstance] account:0];
      nyplAccount.eulaIsAccepted = YES;
      [[NYPLSettings sharedSettings] setUserHasSeenWelcomeScreen:YES];

    }
    
    [self reloadSelectedLibraryAccount];
    
    if (settings.acceptedEULABeforeMultiLibrary == NO) {
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
  else
  {
    Account *account = [[AccountsManager sharedInstance] currentAccount];

    if ((account.needsAuth
        && ![[NYPLAccount sharedAccount:account.id] hasBarcodeAndPIN]) || !account.needsAuth)
    {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:NYPLSyncEndedNotification object:nil];
      }];
    }
    
  }
  
}

@end
