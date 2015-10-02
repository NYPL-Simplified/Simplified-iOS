#import "HSHelpStack.h"
#import "HSZenDeskGear.h"
#import "NYPLConfiguration.h"
#import "NYPLBookRegistry.h"
#import "NYPLReaderSettings.h"
#import "NYPLRootTabBarController.h"
#import "NYPLEULAViewController.h"

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
  
  // Finally (we hope) launch the book modal view
  NYPLBookDetailViewController *modalBookController = [[NYPLBookDetailViewController alloc] initWithBook:book];
  [self.window.rootViewController presentViewController:modalBookController animated:YES completion:^{
    NSLog(@"Guess we're done");
  }];
  
  return YES;
}

- (void)applicationDidEnterBackground:(__attribute__((unused)) UIApplication *)application
{
  [[NYPLBookRegistry sharedRegistry] save];
  [[NYPLReaderSettings sharedSettings] save];
}

@end
