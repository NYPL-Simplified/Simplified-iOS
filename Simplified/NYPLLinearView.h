typedef NS_ENUM(NSInteger, NYPLLinearViewContentVerticalAlignment) {
  NYPLLinearViewContentVerticalAlignmentTop,
  NYPLLinearViewContentVerticalAlignmentMiddle,
  NYPLLinearViewContentVerticalAlignmentBottom
};

@interface NYPLLinearView : UIView

@property (nonatomic) NYPLLinearViewContentVerticalAlignment contentVerticalAlignment;
@property (nonatomic) CGFloat padding;

@end
