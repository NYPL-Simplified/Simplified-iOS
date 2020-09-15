// This class does NOT provide configuration for the following files:
// credits.css

@import UIKit;

@interface NYPLConfiguration : NSObject

+ (id)new NS_UNAVAILABLE;

+ (BOOL)cardCreationEnabled;

// This can be overriden by setting |customMainFeedURL| in NYPLSettings.
+ (NSURL *)mainFeedURL;

+ (NSURL *)minimumVersionURL;

+ (UIColor *)accentColor;

+ (UIColor *)backgroundColor;

+ (UIColor *)readerBackgroundColor;

+ (UIColor *)readerBackgroundDarkColor;

+ (UIColor *)readerBackgroundSepiaColor;

+ (NSString *)systemFontName;

+ (NSString *)systemFontFamilyName;

+ (NSString *)boldSystemFontName;

+ (UIColor *)backgroundMediaOverlayHighlightColor;

+ (UIColor *)backgroundMediaOverlayHighlightDarkColor;

+ (UIColor *)backgroundMediaOverlayHighlightSepiaColor;

+ (CGFloat)defaultTOCRowHeight;

+ (CGFloat)defaultBookmarkRowHeight;

@end
