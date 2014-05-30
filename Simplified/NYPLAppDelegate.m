#import "NYPLRootTabBarController.h"

#import "NYPLAppDelegate.h"

@implementation NYPLAppDelegate

- (BOOL)application:(__attribute__((unused)) UIApplication *const)application
didFinishLaunchingWithOptions:(__attribute__((unused)) NSDictionary *const)launchOptions
{
  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  self.window.rootViewController = [[NYPLRootTabBarController alloc] init];
  [self.window makeKeyAndVisible];

  return YES;
}

@end
