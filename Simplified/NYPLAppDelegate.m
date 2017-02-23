#import "SimplyE-Swift.h"

#import "NYPLConfiguration.h"
#import "NYPLBookRegistry.h"
#import "NYPLReaderSettings.h"
#import "NYPLRootTabBarController.h"
#import "NYPLEULAViewController.h"
#import "NYPLSettings.h"

@import BCLUrms;

#if defined(FEATURE_DRM_CONNECTOR)
#import <ADEPT/ADEPT.h>
#import "NYPLAccount.h"
#import "NYPLSettingsAccountViewController.h"
#endif

// TODO: Remove these imports and move handling the "open a book url" code to a more appropriate handler
#import "NYPLXML.h"
#import "NYPLOPDSEntry.h"
#import "NYPLBook.h"
#import "NYPLBookDetailViewController.h"
#import "NSURL+NYPLURLAdditions.h"

#import "NYPLAppDelegate.h"

@implementation NYPLAppDelegate

#pragma mark UIApplicationDelegate

- (BOOL)application:(__attribute__((unused)) UIApplication *)application
didFinishLaunchingWithOptions:(__attribute__((unused)) NSDictionary *)launchOptions
{
  // This is normally not called directly, but we put all programmatic appearance setup in
  // NYPLConfiguration's class initializer.
  [NYPLConfiguration initialize];

  [BCLUrmsInitializer initializeWithApiKey:@"4f22965e1bf7679114850aac7ff644fefabc9af5"
    marlinURL:@"https://urms-marlin-us.codefusion.technology/bks/"];

  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  self.window.tintColor = [NYPLConfiguration mainColor];
  self.window.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
  [self.window makeKeyAndVisible];
  
  if ([[NYPLSettings sharedSettings] userAcceptedEULA]) {
    self.window.rootViewController = [NYPLRootTabBarController sharedController];
    [self beginCheckingForUpdates];
  } else {
    NYPLRootTabBarController *mainViewController = [NYPLRootTabBarController sharedController];
    UIViewController *eulaViewController = [[NYPLEULAViewController alloc] initWithCompletionHandler:^(void) {
      [UIView transitionWithView:self.window
                        duration:0.5
                         options:UIViewAnimationOptionTransitionCurlUp
                      animations:^() {self.window.rootViewController = mainViewController; }
                      completion:nil];
      [self beginCheckingForUpdates];
    }];
    self.window.rootViewController = eulaViewController;
  }
  
  return YES;
}

- (BOOL)application:(__attribute__((unused)) UIApplication *)application handleOpenURL:(NSURL *)url
{
  // The url has the simplifiedapp scheme; we want to give it the http scheme
  NSURL *entryURL = [url URLBySwappingForScheme:@"http"];
  
  // Get XML from the url, which should be a permalink to a feed URL
  NSData *data = [NSData dataWithContentsOfURL:entryURL];
  
  // Turn the raw data into a real XML
  NYPLXML *xml = [NYPLXML XMLWithData:data];
  
  // Throw that xml at a NYPLOPDSEntry
  NYPLOPDSEntry *entry = [[NYPLOPDSEntry alloc] initWithXML:xml];
  
  // Create a book from the entry
  NYPLBook *book = [NYPLBook bookWithEntry:entry];
  if(!book) {
    NYPLLOG(@"Failed to create book from entry.");
    return NO;
  }
  
  // Finally (we hope) launch the book modal view
  NYPLBookDetailViewController *modalBookController = [[NYPLBookDetailViewController alloc] initWithBook:book];
  NYPLRootTabBarController *tbc = (NYPLRootTabBarController *) self.window.rootViewController;
  
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    if ([tbc.selectedViewController isKindOfClass:[UINavigationController class]])
      [tbc.selectedViewController pushViewController:modalBookController animated:YES];
  } else {
    [tbc.selectedViewController presentViewController:modalBookController animated:YES completion:nil];
  }
  
  return YES;
}

- (void)applicationWillResignActive:(__attribute__((unused)) UIApplication *)application
{
  [[NYPLBookRegistry sharedRegistry] save];
  [[NYPLReaderSettings sharedSettings] save];
}

- (void)applicationWillTerminate:(__unused UIApplication *)application
{
  [[NYPLBookRegistry sharedRegistry] save];
  [[NYPLReaderSettings sharedSettings] save];
}

#if defined(FEATURE_DRM_CONNECTOR)
- (void)applicationDidBecomeActive:(__unused UIApplication *)application
{
  if (![[NYPLADEPT sharedInstance] deviceAuthorized]) {
    if ([[NYPLAccount sharedAccount] hasBarcodeAndPIN]) {
      [NYPLSettingsAccountViewController authorizeUsingExistingBarcodeAndPinWithCompletionHandler:nil];
    }
  }

}
#endif

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
