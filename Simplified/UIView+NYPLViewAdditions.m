#import "UIView+NYPLViewAdditions.h"

@implementation UIView (NYPLViewAdditions)

- (CGFloat)preferredHeight
{
  return [self sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)].height;
}

- (CGFloat)preferredWidth
{
  return [self sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)].width;
}

- (void)integralizeFrame
{
  self.frame = CGRectIntegral(self.frame);
}

@end
