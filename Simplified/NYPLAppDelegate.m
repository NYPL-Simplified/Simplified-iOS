#import "NYPLConfiguration.h"
#import "NYPLMyBooksRegistry.h"
#import "NYPLReaderSettings.h"
#import "NYPLRootTabBarController.h"

#import "NYPLAppDelegate.h"

@implementation NYPLAppDelegate

#pragma mark UIApplicationDelegate

- (BOOL)application:(__attribute__((unused)) UIApplication *)application
didFinishLaunchingWithOptions:(__attribute__((unused)) NSDictionary *)launchOptions
{
  // This is normally not called directly, but we put all programmatic appearance setup in
  // NYPLConfiguration's class initializer.
  [NYPLConfiguration initialize];
  
  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  self.window.tintColor = [NYPLConfiguration mainColor];
  self.window.rootViewController = [NYPLRootTabBarController sharedController];
  self.window.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
  [self.window makeKeyAndVisible];

  return YES;
}

- (void)applicationDidEnterBackground:(__attribute__((unused)) UIApplication *)application
{
  [[NYPLMyBooksRegistry sharedRegistry] save];
  [[NYPLReaderSettings sharedSettings] save];
}

@end
