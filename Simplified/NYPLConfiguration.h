// This class does NOT provide configuration for the following files:
// credits.css

@import UIKit;

@interface NYPLConfiguration : NSObject

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (BOOL) bugsnagEnabled;

+ (NSString *)bugsnagID;

+ (BOOL)cardCreationEnabled;

// This can be overriden by setting |customMainFeedURL| in NYPLSettings.
+ (NSURL *)mainFeedURL;

+ (NSURL *)loanURL;


+ (NSURL *)minimumVersionURL;

+ (UIColor *)colorFromHexString:(NSString *)hexString;

+ (UIColor *)mainColor;

+ (UIColor *)accentColor;

+ (UIColor *)backgroundColor;

+ (UIColor *)backgroundDarkColor;

+ (UIColor *)backgroundSepiaColor;

+ (UIColor *)iconLogoBlueColor;

+ (UIColor *)iconLogoGreenColor;

+ (NSString *)systemFontName;

+ (NSString *)boldSystemFontName;

+ (UIColor *)backgroundMediaOverlayHighlightColor;

+ (UIColor *)backgroundMediaOverlayHighlightDarkColor;

+ (UIColor *)backgroundMediaOverlayHighlightSepiaColor;

@end
