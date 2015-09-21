#import "HSHelpStack.h"
#import "HSZenDeskGear.h"
#import "NYPLConfiguration.h"
#import "NYPLBookRegistry.h"
#import "NYPLReaderSettings.h"
#import "NYPLRootTabBarController.h"
#import "NYPLEULAViewController.h"

#import "NYPLAppDelegate.h"

@implementation NYPLAppDelegate

#pragma mark UIApplicationDelegate

- (BOOL)application:(__attribute__((unused)) UIApplication *)application
didFinishLaunchingWithOptions:(__attribute__((unused)) NSDictionary *)launchOptions
{
  // This is normally not called directly, but we put all programmatic appearance setup in
  // NYPLConfiguration's class initializer.
  [NYPLConfiguration initialize];
  
  [[HSHelpStack instance] setThemeFrompList:@"HelpStackTheme"];
  HSZenDeskGear *zenDeskGear  = [[HSZenDeskGear alloc]
                                 initWithInstanceUrl : @"https://nypl.zendesk.com"
                                 staffEmailAddress   : @"johannesneuer@nypl.org"
                                 apiToken            : @"P6aFczYFc4al6o2riRBogWLi5D0M0QCdrON6isJi"];
  
  HSHelpStack *helpStack = [HSHelpStack instance];
  helpStack.gear = zenDeskGear;
  
  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  self.window.tintColor = [NYPLConfiguration mainColor];
  self.window.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
  [self.window makeKeyAndVisible];
  
  UIViewController *eulaViewController = [[NYPLEULAViewController alloc] initWithCompletionHandler:^(void) {
    self.window.rootViewController = [NYPLRootTabBarController sharedController];
  }];
  
  self.window.rootViewController = eulaViewController;
  
  return YES;
}

- (void)applicationDidEnterBackground:(__attribute__((unused)) UIApplication *)application
{
  [[NYPLBookRegistry sharedRegistry] save];
  [[NYPLReaderSettings sharedSettings] save];
}

@end
