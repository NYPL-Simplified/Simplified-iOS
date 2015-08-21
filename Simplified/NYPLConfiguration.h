// This class does NOT provide configuration for the following files:
// credits.css

@interface NYPLConfiguration : NSObject

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (NSURL *)circulationURL;

// This can be overriden by setting |customMainFeedURL| in NYPLSettings.
+ (NSURL *)mainFeedURL;

+ (NSURL *)loanURL;

+ (NSURL *)registrationURL;

+ (UIColor *)mainColor;

+ (UIColor *)accentColor;

+ (UIColor *)backgroundColor;

+ (UIColor *)backgroundDarkColor;

+ (UIColor *)backgroundSepiaColor;

+ (NSString *)systemFontName;

+ (NSString *)boldSystemFontName;

@end
