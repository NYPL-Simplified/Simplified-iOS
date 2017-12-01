@interface NYPLRoundedButton : UIButton

+ (id)buttonWithType:(UIButtonType)buttonType NS_UNAVAILABLE;
+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

+ (instancetype)button;

@end
