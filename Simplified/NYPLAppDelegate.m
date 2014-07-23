#import "NYPLConfiguration.h"
#import "NYPLMyBooksRegistry.h"
#import "NYPLRootTabBarController.h"

#import "NYPLAppDelegate.h"

@implementation NYPLAppDelegate

#pragma mark UIApplicationDelegate

- (BOOL)application:(__attribute__((unused)) UIApplication *)application
didFinishLaunchingWithOptions:(__attribute__((unused)) NSDictionary *)launchOptions
{
  [NYPLConfiguration initialize];
  
  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  self.window.tintColor = [NYPLConfiguration mainColor];
  self.window.rootViewController = [[NYPLRootTabBarController alloc] init];
  [self.window makeKeyAndVisible];

  return YES;
}

- (void)applicationDidEnterBackground:(__attribute__((unused)) UIApplication *)application
{
  [[NYPLMyBooksRegistry sharedRegistry] save];
}

@end
