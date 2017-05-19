@interface UIFont (NYPLSystemFontOverride)

+ (UIFont *)customFontForTextStyle:(UIFontTextStyle)style;
+ (UIFont *)customFontForTextStyle:(UIFontTextStyle)style multiplier:(CGFloat)multiplier;
+ (UIFont *)customBoldFontForTextStyle:(UIFontTextStyle)style;

@end
