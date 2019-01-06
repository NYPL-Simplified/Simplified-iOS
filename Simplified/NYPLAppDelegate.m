@import NYPLAudiobookToolkit;
@import NotificationCenter;
@import UserNotifications;

#import "SimplyE-Swift.h"

#import "NYPLAlertController.h"
#import "NYPLConfiguration.h"
#import "NYPLBookRegistry.h"
#import "NYPLReachability.h"
#import "NYPLReaderSettings.h"
#import "NYPLRootTabBarController.h"
#import "NYPLSettings.h"

#if defined(FEATURE_DRM_CONNECTOR)
#import <ADEPT/ADEPT.h>
#import "NYPLAccount.h"
#import "NYPLAccountSignInViewController.h"
#endif

// TODO: Remove these imports and move handling the "open a book url" code to a more appropriate handler
#import "NYPLXML.h"
#import "NYPLOPDSEntry.h"
#import "NYPLBook.h"
#import "NYPLBookDetailViewController.h"
#import "NSURL+NYPLURLAdditions.h"

#import "NYPLAppDelegate.h"

@interface NYPLAppDelegate()

@property (nonatomic) AudiobookLifecycleManager *audiobookLifecycleManager;
@property (nonatomic) NYPLReachability *reachabilityManager;

@end

@implementation NYPLAppDelegate

const double MininumBackgroundFetchInterval = 60 * 60 * 12;

#pragma mark UIApplicationDelegate

- (BOOL)application:(__attribute__((unused)) UIApplication *)application
didFinishLaunchingWithOptions:(__attribute__((unused)) NSDictionary *)launchOptions
{
  [[UIApplication sharedApplication]
   setMinimumBackgroundFetchInterval:MininumBackgroundFetchInterval];

  [NYPLKeychainManager validateKeychain];
  
  self.audiobookLifecycleManager = [[AudiobookLifecycleManager alloc] init];
  [self.audiobookLifecycleManager didFinishLaunching];

  // Initiallize Accounts from JSON file
  [AccountsManager sharedInstance];
  // This is normally not called directly, but we put all programmatic appearance setup in
  // NYPLConfiguration's class initializer.
  [NYPLConfiguration initialize];
  // Initialize Offline Requests Queue
  [NetworkQueue shared];
  self.reachabilityManager = [NYPLReachability sharedReachability];
  
  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  self.window.tintColor = [NYPLConfiguration mainColor];
  self.window.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
  [self.window makeKeyAndVisible];
  
  NYPLRootTabBarController *vc = [NYPLRootTabBarController sharedController];
  self.window.rootViewController = vc;
    
  [self beginCheckingForUpdates];

  return YES;
}

- (void)application:(__attribute__((unused)) UIApplication *)application
performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
  [[NYPLBookRegistry sharedRegistry] syncWithCompletionHandler:^(BOOL __unused success) {
    //GODO this block is not being called in a lot of places. come back to this.
    //GODO is a sync being called anywhere else when the app launches?
    completionHandler(UIBackgroundFetchResultNewData);
  }];
}

- (BOOL)application:(__attribute__((unused)) UIApplication *)application handleOpenURL:(NSURL *)url
{
  // URLs should be a permalink to a feed URL
  NSURL *entryURL = [url URLBySwappingForScheme:@"http"];
  NSData *data = [NSData dataWithContentsOfURL:entryURL];
  NYPLXML *xml = [NYPLXML XMLWithData:data];
  NYPLOPDSEntry *entry = [[NYPLOPDSEntry alloc] initWithXML:xml];
  
  NYPLBook *book = [NYPLBook bookWithEntry:entry];
  if(!book) {
    NSString *alertTitle = @"Error Opening Link";
    NSString *alertMessage = @"There was an error opening the linked book.";
    [NYPLAlertController alertWithTitle:alertTitle message:alertMessage];
    NYPLLOG(@"Failed to create book from deep-linked URL.");
    return NO;
  }
  
  NYPLBookDetailViewController *bookDetailVC = [[NYPLBookDetailViewController alloc] initWithBook:book];
  NYPLRootTabBarController *tbc = (NYPLRootTabBarController *) self.window.rootViewController;

  if (!tbc || ![tbc.selectedViewController isKindOfClass:[UINavigationController class]]) {
    NYPLLOG(@"Casted views were not of expected types.");
    return NO;
  }

  [tbc setSelectedIndex:0];

  // Presentation logic should match 'presentFromViewController:' in NYPLBookDetailViewController
  UINavigationController *navFormSheet = (UINavigationController *) tbc.selectedViewController.presentedViewController;
  if (tbc.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
    [tbc.selectedViewController pushViewController:bookDetailVC animated:YES];
  } else if (navFormSheet) {
    [navFormSheet pushViewController:bookDetailVC animated:YES];
  } else {
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:bookDetailVC];
    navVC.modalPresentationStyle = UIModalPresentationFormSheet;
    [tbc.selectedViewController presentViewController:navVC animated:YES completion:nil];
  }

  return YES;
}

- (void)applicationWillResignActive:(__attribute__((unused)) UIApplication *)application
{
  [[NYPLBookRegistry sharedRegistry] save];
  [[NYPLReaderSettings sharedSettings] save];
}

- (void)applicationDidEnterBackground:(__unused UIApplication *)application
{
  [self.audiobookLifecycleManager didEnterBackground];
}

- (void)applicationWillTerminate:(__unused UIApplication *)application
{
  [self.audiobookLifecycleManager willTerminate];
  [[NYPLBookRegistry sharedRegistry] save];
  [[NYPLReaderSettings sharedSettings] save];
}

- (void)application:(__unused UIApplication *)application
handleEventsForBackgroundURLSession:(NSString *const)identifier
completionHandler:(void (^const)(void))completionHandler
{
  [self.audiobookLifecycleManager
   handleEventsForBackgroundURLSessionFor:identifier
   completionHandler:completionHandler];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
  //GODO: Audit the badging logic to make sure we want it this way
  application.applicationIconBadgeNumber = notification.applicationIconBadgeNumber - 1;

  //GODO: Check to see if it's the correct type of notification. maybe send to My Books and not My Reservations
  //GODO: This also will break if you've switched the library (or have a no-auth library)
}

- (void)beginCheckingForUpdates
{
  [UpdateCheckShim
   performUpdateCheckWithURL:[NYPLConfiguration minimumVersionURL]
   handler:^(NSString *_Nonnull version, NSURL *_Nonnull updateURL) {
     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
       UIAlertController *const alertController =
         [UIAlertController
          alertControllerWithTitle:NSLocalizedString(@"AppDelegateUpdateRequiredTitle", nil)
          message:[NSString stringWithFormat:NSLocalizedString(@"AppDelegateUpdateRequiredMessageFormat", nil), version]
          preferredStyle:UIAlertControllerStyleAlert];
       [alertController addAction:
        [UIAlertAction
         actionWithTitle:NSLocalizedString(@"AppDelegateUpdateNow", nil)
         style:UIAlertActionStyleDefault
         handler:^(__unused UIAlertAction *_Nonnull action) {
           [[UIApplication sharedApplication] openURL:updateURL];
         }]];
       [alertController addAction:
        [UIAlertAction
         actionWithTitle:NSLocalizedString(@"AppDelegateUpdateRemindMeLater", nil)
         style:UIAlertActionStyleCancel
         handler:nil]];
       [self.window.rootViewController
        presentViewController:alertController
        animated:YES
        completion:^{
          // Try again in 24 hours or on next launch, whichever is sooner.
          [self performSelector:@selector(beginCheckingForUpdates)
                     withObject:nil
                     afterDelay:(60 * 60 * 24)];
        }];
     }];
   }];
}

@end
