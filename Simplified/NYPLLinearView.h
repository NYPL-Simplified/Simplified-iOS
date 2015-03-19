typedef NS_ENUM(NSInteger, NYPLLinearViewContentVerticalAlignment) {
  NYPLLinearViewContentVerticalAlignmentTop,
  NYPLLinearViewContentVerticalAlignmentMiddle,
  NYPLLinearViewContentVerticalAlignmentBottom
};

@interface NYPLLinearView : UIView

// This defaults to |NYPLLinearViewContentVerticalAlignmentTop|.
@property (nonatomic) NYPLLinearViewContentVerticalAlignment contentVerticalAlignment;

// This defaults to 0.
@property (nonatomic) CGFloat padding;

@end
