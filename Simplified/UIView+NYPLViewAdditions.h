@interface UIView (NYPLViewAdditions)

@property (nonatomic, readonly) CGFloat preferredHeight;
@property (nonatomic, readonly) CGFloat preferredWidth;

- (void)integralizeFrame;

@end
