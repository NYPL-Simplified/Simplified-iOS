@interface NYPLConfiguration : NSObject

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (NSURL *)mainFeedURL;

// If set, this will override the default value for |mainFeedURL|. Set it to nil to resume using the
// default URL.
+ (NSURL *)developmentFeedURL;

+ (void)setDevelopmentFeedURL:(NSURL *)URL;

+ (NSURL *)loanURL;

+ (UIColor *)mainColor;

+ (UIColor *)accentColor;

+ (UIColor *)backgroundColor;

+ (UIColor *)backgroundDarkColor;

+ (UIColor *)backgroundSepiaColor;

+ (NSString *)systemFontName;

+ (NSString *)boldSystemFontName;

@end
