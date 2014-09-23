#import "NYPLRoundedButton.h"

@implementation NYPLRoundedButton

+ (instancetype)button
{
  // The cast lets us call the constructor even though it's marked NS_UNAVAILABLE.
  NYPLRoundedButton *const button = [(id)self buttonWithType:UIButtonTypeSystem];
  
  button.titleLabel.font = [UIFont systemFontOfSize:12];
  button.titleEdgeInsets = UIEdgeInsetsMake(2.0, 0, 0, 0);
  button.layer.borderColor = button.tintColor.CGColor;
  button.layer.borderWidth = 1;
  button.layer.cornerRadius = 3;

  return button;
}

#pragma mark UIView

- (CGSize)sizeThatFits:(CGSize const)size
{
  CGSize s = [super sizeThatFits:size];
  s.width += 16;
  return s;
}

- (void)tintColorDidChange
{
  [super tintColorDidChange];
  
  self.layer.borderColor = self.tintColor.CGColor;
}

@end
