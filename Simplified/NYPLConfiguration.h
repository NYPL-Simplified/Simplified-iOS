@interface NYPLConfiguration : NSObject

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (NSURL *)mainFeedURL;

+ (NSURL *)loanURL;

+ (UIColor *)mainColor;

+ (UIColor *)accentColor;

+ (UIColor *)backgroundColor;

+ (NSString *)systemFontName;

+ (NSString *)boldSystemFontName;

@end
