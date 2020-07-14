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

- (void)centerInSuperview
{
  self.center = CGPointMake(CGRectGetWidth(self.superview.bounds) * 0.5,
                            CGRectGetHeight(self.superview.bounds) * 0.5);
  [self integralizeFrame];
}

- (void)centerInSuperviewWithOffset:(CGPoint)offset
{
  self.center = CGPointMake(CGRectGetWidth(self.superview.bounds) * 0.5 + offset.x,
                            CGRectGetHeight(self.superview.bounds) * 0.5 + offset.y);
  [self integralizeFrame];
}

- (void)integralizeFrame
{
  self.frame = CGRectIntegral(self.frame);
}

@end
