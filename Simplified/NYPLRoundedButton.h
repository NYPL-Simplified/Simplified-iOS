typedef NS_ENUM(NSInteger, NYPLRoundedButtonType) {
  NYPLRoundedButtonTypeNormal = 0,
  NYPLRoundedButtonTypeClock,
  NYPLRoundedButtonTypeQueue
};

@interface NYPLRoundedButton : UIButton

+ (id)buttonWithType:(UIButtonType)buttonType NS_UNAVAILABLE;
+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

@property (nonatomic) NYPLRoundedButtonType type;
@property (nonatomic) NSInteger queuePosition;
@property (nonatomic) NSDate *endDate;
@property (nonatomic) BOOL fromDetailView;

+ (instancetype)button;

@end
