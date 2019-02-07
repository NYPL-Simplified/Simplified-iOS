@import Bugsnag;

#import "NYPLConfiguration.h"
#import "NYPLAccount.h"
#import "NYPLAppDelegate.h"
#import "NYPLBugsnagLogs.h"
#import "NYPLSettings.h"

#import "UILabel+NYPLAppearanceAdditions.h"
#import "UIButton+NYPLAppearanceAdditions.h"
#import "SimplyE-Swift.h"

#if defined(FEATURE_DRM_CONNECTOR)
#import <ADEPT/ADEPT.h>
#endif

@implementation NYPLConfiguration

+ (void)initialize
{
  static dispatch_once_t onceToken;
  dispatch_once (&onceToken, ^{
    dispatch_async(dispatch_get_main_queue(), ^{
      [self configureCrashAnalytics];
    });
  });
}

+ (void)configureCrashAnalytics
{
  if (!TARGET_OS_SIMULATOR) {
    BugsnagConfiguration *config = [BugsnagConfiguration new];
    config.apiKey = [APIKeys bugsnagID];

    if (DEBUG) {
      config.releaseStage = @"development";
    } else if ([self releaseStageIsBeta]) {
      config.releaseStage = @"beta";
      if ([[NYPLAccount sharedAccount] barcode]) {
        [config setUser:[[NYPLAccount sharedAccount] barcode] withName:nil andEmail:nil];
      }
    } else {
      config.releaseStage = @"production";
    }

    [Bugsnag startBugsnagWithConfiguration:config];
    [NYPLBugsnagLogs reportNewActiveSession];
  }
}

+ (BOOL)releaseStageIsBeta
{
  NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
  return ([[receiptURL path] rangeOfString:@"sandboxReceipt"].location != NSNotFound);
}

+ (NSURL *)mainFeedURL
{
  NSURL *const customURL = [NYPLSettings sharedSettings].customMainFeedURL;

  if(customURL) return customURL;

  NSURL *const accountURL = [NYPLSettings sharedSettings].accountMainFeedURL;
  
  if(accountURL) return accountURL;

  return nil;
}

+ (NSURL *)loanURL
{
  return [[self mainFeedURL] URLByAppendingPathComponent:@"loans"];
}

+ (BOOL)cardCreationEnabled
{
  return YES;
}

+ (NSURL *)minimumVersionURL
{
  return [NSURL URLWithString:@"http://www.librarysimplified.org/simplye-client/minimum-version"];
}

+ (UIColor *)mainColor
{
  Account *const account = [AccountsManager shared].currentAccount;

  if (account.mainColor) {
    return [NYPLAppTheme themeColorFromStringWithName:account.mainColor];
  } else {
    return [UIColor blackColor];
  }
}

+ (UIColor *)accentColor
{
  return [UIColor colorWithRed:0.0/255.0 green:144/255.0 blue:196/255.0 alpha:1.0];
}

+ (UIColor *)backgroundColor
{
  return [UIColor colorWithWhite:250/255.0 alpha:1.0];
}

+ (UIColor *)backgroundDarkColor
{
  return [UIColor colorWithWhite:5/255.0 alpha:1.0];
}

+ (UIColor *)backgroundSepiaColor
{
  return [UIColor colorWithRed:242/255.0 green:228/255.0 blue:203/255.0 alpha:1.0];
}

+(UIColor *)backgroundMediaOverlayHighlightColor {
  return [UIColor yellowColor];
}

+(UIColor *)backgroundMediaOverlayHighlightDarkColor {
  return [UIColor orangeColor];
}

+(UIColor *)backgroundMediaOverlayHighlightSepiaColor {
  return [UIColor yellowColor];
}

+(UIColor *)iconLogoBlueColor {
  return [UIColor colorWithRed:17.0/255.0 green:50.0/255.0 blue:84.0/255.0 alpha:1.0];
}

+(UIColor *)iconLogoGreenColor {
  return [UIColor colorWithRed:141.0/255.0 green:199.0/255.0 blue:64.0/255.0 alpha:1.0];
}

// Set for the whole app via UIView+NYPLFontAdditions.
+ (NSString *)systemFontName
{
  return @"AvenirNext-Medium";
}

// Set for the whole app via UIView+NYPLFontAdditions.
+ (NSString *)boldSystemFontName
{
  return @"AvenirNext-Bold";
}

+ (NSString *)systemFontFamilyName
{
  return @"Avenir Next";
}

@end
