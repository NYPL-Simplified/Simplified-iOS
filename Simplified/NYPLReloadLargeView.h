@interface NYPLReloadLargeView : UIView

// As always, beware of creating reference cycles when setting handlers that refer to |self|.
@property (nonatomic, strong) void (^handler)();

+ (id)new NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

@end