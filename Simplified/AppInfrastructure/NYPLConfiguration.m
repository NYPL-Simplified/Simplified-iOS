#import "NYPLConfiguration.h"
#import "NYPLAppDelegate.h"

#import "UILabel+NYPLAppearanceAdditions.h"
#import "UIButton+NYPLAppearanceAdditions.h"
#import "SimplyE-Swift.h"

#if defined(FEATURE_DRM_CONNECTOR)
#import <ADEPT/ADEPT.h>
#endif

@implementation NYPLConfiguration

+ (NSURL *)mainFeedURL
{
  NSURL *const customURL = [NYPLSettings sharedSettings].customMainFeedURL;

  if(customURL) return customURL;

  NSURL *const accountURL = [NYPLSettings sharedSettings].accountMainFeedURL;
  
  if(accountURL) return accountURL;

  return nil;
}

+ (BOOL)cardCreationEnabled
{
  return YES;
}

+ (NSURL *)minimumVersionURL
{
  return [NSURL URLWithString:@"http://www.librarysimplified.org/simplye-client/minimum-version"];
}

+ (UIColor *)accentColor
{
  return [UIColor colorWithRed:0.0/255.0 green:144/255.0 blue:196/255.0 alpha:1.0];
}

+ (UIColor *)backgroundColor
{
  if (@available(iOS 13, *)) {
    return [UIColor colorNamed: @"ColorBackground"];
  }
  return [UIColor colorWithWhite:250/255.0 alpha:1.0];
}

+ (UIColor *)readerBackgroundColor
{
  return [UIColor colorWithWhite:250/255.0 alpha:1.0];
}

// OK to leave as static color because it's reader-only
+ (UIColor *)readerBackgroundDarkColor
{
  return [UIColor colorWithWhite:5/255.0 alpha:1.0];
}

// OK to leave as static color because it's reader-only
+ (UIColor *)readerBackgroundSepiaColor
{
  return [UIColor colorWithRed:242/255.0 green:228/255.0 blue:203/255.0 alpha:1.0];
}

// OK to leave as static color because it's reader-only
+(UIColor *)backgroundMediaOverlayHighlightColor {
  return [UIColor yellowColor];
}

// OK to leave as static color because it's reader-only
+(UIColor *)backgroundMediaOverlayHighlightDarkColor {
  return [UIColor orangeColor];
}

// OK to leave as static color because it's reader-only
+(UIColor *)backgroundMediaOverlayHighlightSepiaColor {
  return [UIColor yellowColor];
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
