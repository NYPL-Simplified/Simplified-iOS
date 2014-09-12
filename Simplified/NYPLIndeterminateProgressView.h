@interface NYPLIndeterminateProgressView : UIView

@property (nonatomic, readonly) BOOL animating; // default NO
@property (nonatomic) UIColor *color;           // default [UIColor lightGreyColor]
@property (nonatomic) CGFloat speedMultiplier;  // default 1.0

- (void)startAnimating;

- (void)stopAnimating;

@end
