// This class does NOT provide configuration for the following files:
// credits.css

@interface NYPLConfiguration : NSObject

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (BOOL) heapEnabled;

+ (BOOL) bugsnagEnabled;

+ (NSString *)heapID;

+ (NSString *)bugsnagID;

+ (NSURL *)circulationURL;

// This can be overriden by setting |customMainFeedURL| in NYPLSettings.
+ (NSURL *)mainFeedURL;

+ (BOOL)customFeedEnabled;

+ (NSURL *)loanURL;

+ (NSURL *)registrationURL;

+ (UIColor *)mainColor;

+ (UIColor *)accentColor;

+ (UIColor *)backgroundColor;

+ (UIColor *)backgroundDarkColor;

+ (UIColor *)backgroundSepiaColor;

+ (NSString *)systemFontName;

+ (NSString *)boldSystemFontName;

+ (UIColor *)backgroundMediaOverlayHighlightColor;

+ (UIColor *)backgroundMediaOverlayHighlightDarkColor;

+ (UIColor *)backgroundMediaOverlayHighlightSepiaColor;

@end
