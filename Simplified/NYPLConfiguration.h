@interface NYPLConfiguration : NSObject

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

// This can be overriden by setting |customMainFeedURL| in NYPLSettings.
+ (NSURL *)mainFeedURL;

+ (NSURL *)loanURL;

+ (UIColor *)mainColor;

+ (UIColor *)accentColor;

+ (UIColor *)backgroundColor;

+ (UIColor *)backgroundDarkColor;

+ (UIColor *)backgroundSepiaColor;

+ (NSString *)systemFontName;

+ (NSString *)boldSystemFontName;

@end
