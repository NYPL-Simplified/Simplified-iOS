#import "NYPLSettings.h"
#import "Bugsnag.h"
#import "HSHelpStack.h"
#import "HSDeskGear.h"

#if defined(FEATURE_DRM_CONNECTOR)
#import <ADEPT/ADEPT.h>
#endif

#import "NYPLConfiguration.h"
#import "UILabel+NYPLAppearanceAdditions.h"
#import "UIButton+NYPLAppearanceAdditions.h"
#import "SimplyE-Swift.h"
#import "NYPLAppDelegate.h"

@implementation NYPLConfiguration

+ (void)initialize
{
  if([NYPLConfiguration bugsnagEnabled]) {
    [Bugsnag startBugsnagWithApiKey:[NYPLConfiguration bugsnagID]];
  }
  
#if defined(FEATURE_DRM_CONNECTOR)
  [[NYPLADEPT sharedInstance] setLogCallback:^(__unused NSString *logLevel,
                                               NSString *const exceptionName,
                                               __unused NSDictionary *data,
                                               NSString *const message) {
    NSLog(@"ADEPT: %@: %@", exceptionName, message);
  }];
#endif
}


+ (BOOL) bugsnagEnabled
{
  return !TARGET_OS_SIMULATOR;
}


+ (NSString *) bugsnagID
{
  return @"76cb0080ae8cc30d903663e10b138381";
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


+ (UIColor *)colorFromHexString:(NSString *)hexString {
  unsigned rgbValue = 0;
  NSScanner *scanner = [NSScanner scannerWithString:hexString];
  [scanner setScanLocation:1]; // bypass '#' character
  [scanner scanHexInt:&rgbValue];
  return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

+ (NSURL *)minimumVersionURL
{
  return [NSURL URLWithString:@"http://www.librarysimplified.org/simplye-client/minimum-version"];
}

+ (UIColor *)mainColor
{
  Account * account = [[NYPLSettings sharedSettings] currentAccount];

  if (account.mainColor == nil)
  {
    return [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
  }
  return [NYPLConfiguration colorFromHexString:[NSString stringWithFormat:@"#%@",account.mainColor]];
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

@end
