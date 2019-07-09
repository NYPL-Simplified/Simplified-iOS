// This class does NOT provide configuration for the following files:
// credits.css

@import UIKit;

@interface NYPLConfiguration : NSObject

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (BOOL)cardCreationEnabled;

+ (BOOL)releaseStageIsBeta;

// This can be overriden by setting |customMainFeedURL| in NYPLSettings.
+ (NSURL *)mainFeedURL;

+ (NSURL *)minimumVersionURL;

+ (UIColor *)mainColor;

+ (UIColor *)accentColor;

+ (UIColor *)backgroundColor;

+ (UIColor *)backgroundDarkColor;

+ (UIColor *)backgroundSepiaColor;

+ (UIColor *)iconLogoBlueColor;

+ (UIColor *)iconLogoGreenColor;

+ (NSString *)systemFontName;

+ (NSString *)systemFontFamilyName;

+ (NSString *)boldSystemFontName;

+ (UIColor *)backgroundMediaOverlayHighlightColor;

+ (UIColor *)backgroundMediaOverlayHighlightDarkColor;

+ (UIColor *)backgroundMediaOverlayHighlightSepiaColor;

@end
