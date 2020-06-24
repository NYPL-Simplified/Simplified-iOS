typedef NS_ENUM(NSInteger, NYPLRoundedButtonType) {
  NYPLRoundedButtonTypeNormal = 0,
  NYPLRoundedButtonTypeClock
};

@interface NYPLRoundedButton : UIButton

+ (nonnull id)buttonWithType:(UIButtonType)buttonType NS_UNAVAILABLE;
+ (nonnull id)new NS_UNAVAILABLE;
- (nonnull id)init NS_UNAVAILABLE;
- (nullable id)initWithCoder:(nonnull NSCoder *)aDecoder NS_UNAVAILABLE;
- (nonnull id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

@property (nonatomic) NYPLRoundedButtonType type;
@property (nonatomic, nullable) NSDate *endDate;
@property (nonatomic) BOOL fromDetailView;

+ (nonnull instancetype)button;

@end
