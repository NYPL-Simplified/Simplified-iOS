@import NYPLAudiobookToolkit;

#import "SimplyE-Swift.h"

#import "NYPLConfiguration.h"
#import "NYPLBookRegistry.h"
#import "NYPLReachability.h"
#import "NYPLReaderSettings.h"
#import "NYPLRootTabBarController.h"


#if defined(FEATURE_DRM_CONNECTOR)
#import <ADEPT/ADEPT.h>
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
@property (nonatomic) NYPLUserNotifications *notificationsManager;

@end

@implementation NYPLAppDelegate

const NSTimeInterval MinimumBackgroundFetchInterval = 60 * 60 * 24;

#pragma mark UIApplicationDelegate

- (BOOL)application:(__attribute__((unused)) UIApplication *)application
didFinishLaunchingWithOptions:(__attribute__((unused)) NSDictionary *)launchOptions
{
#if !TARGET_OS_SIMULATOR
  [NYPLErrorLogger configureCrashAnalytics];
#endif

  // Perform data migrations as early as possible before anything has a chance to access them
  [NYPLKeychainManager validateKeychain];
  [MigrationManager migrate];
  
  self.audiobookLifecycleManager = [[AudiobookLifecycleManager alloc] init];
  [self.audiobookLifecycleManager didFinishLaunching];

  [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:MinimumBackgroundFetchInterval];

  if (@available (iOS 10.0, *)) {
    self.notificationsManager = [[NYPLUserNotifications alloc] init];
    [self.notificationsManager authorizeIfNeeded];
  }

  [[NetworkQueue shared] addObserverForOfflineQueue];
  self.reachabilityManager = [NYPLReachability sharedReachability];
  
  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  self.window.tintColor = [NYPLConfiguration mainColor];
  self.window.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
  [self.window makeKeyAndVisible];
  
  NYPLRootTabBarController *vc = [NYPLRootTabBarController sharedController];
  self.window.rootViewController = vc;

  [self beginCheckingForUpdates];

#if !TARGET_OS_SIMULATOR
  [NYPLErrorLogger logNewAppLaunch];
#endif

  return YES;
}

// note: this appears to always be called on main thread while app is on background
- (void)application:(__attribute__((unused)) UIApplication *)application
performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))backgroundFetchHandler
{
  NSDate *startDate = [NSDate date];
  if ([NYPLUserNotifications backgroundFetchIsNeeded]) {
    NYPLLOG_F(@"[Background Fetch] Starting book registry sync. "
              "ElapsedTime=%f", -startDate.timeIntervalSinceNow);
    // Only the "current library" account syncs during a background fetch.
    [[NYPLBookRegistry sharedRegistry] syncResettingCache:NO completionHandler:^(BOOL success) {
      if (success) {
        [[NYPLBookRegistry sharedRegistry] save];
      }
    } backgroundFetchHandler:^(UIBackgroundFetchResult result) {
      NYPLLOG_F(@"[Background Fetch] Completed with result %lu. "
                "ElapsedTime=%f", (unsigned long)result, -startDate.timeIntervalSinceNow);
      backgroundFetchHandler(result);
    }];
  } else {
    NYPLLOG_F(@"[Background Fetch] Registry sync not needed. "
              "ElapsedTime=%f", -startDate.timeIntervalSinceNow);
    backgroundFetchHandler(UIBackgroundFetchResultNewData);
  }
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler
{
    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb] && [userActivity.webpageURL.host isEqualToString:NYPLSettings.shared.authenticationUniversalLink.host]) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"NYPLAppDelegateDidReceiveCleverRedirectURL"
         object:userActivity.webpageURL];

        return YES;
    }

    return NO;
}

- (BOOL)application:(__unused UIApplication *)app
            openURL:(NSURL *)url
            options:(__unused NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{

  // URLs should be a permalink to a feed URL
  NSURL *entryURL = [url URLBySwappingForScheme:@"http"];
  NSData *data = [NSData dataWithContentsOfURL:entryURL];
  NYPLXML *xml = [NYPLXML XMLWithData:data];
  NYPLOPDSEntry *entry = [[NYPLOPDSEntry alloc] initWithXML:xml];
  
  NYPLBook *book = [NYPLBook bookWithEntry:entry];
  if (!book) {
    NSString *alertTitle = @"Error Opening Link";
    NSString *alertMessage = @"There was an error opening the linked book.";
    UIAlertController *alert = [NYPLAlertUtils alertWithTitle:alertTitle message:alertMessage];
    [NYPLAlertUtils presentFromViewControllerOrNilWithAlertController:alert viewController:nil animated:YES completion:nil];
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

-(void)applicationDidBecomeActive:(__unused UIApplication *)app
{
  [NYPLErrorLogger setUserID:[[NYPLUserAccount sharedAccount] barcode]];
}

- (void)applicationWillResignActive:(__attribute__((unused)) UIApplication *)application
{
  [[NYPLBookRegistry sharedRegistry] save];
  [[NYPLReaderSettings sharedSettings] save];
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

#pragma mark -

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
