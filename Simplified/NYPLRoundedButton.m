@import PureLayout;

#import "NYPLRoundedButton.h"
#import "NSDate+NYPLDateAdditions.h"

@interface NYPLRoundedButton ()

@property (nonatomic) UILabel *label;

@end

@implementation NYPLRoundedButton

+ (instancetype)button
{
  // The cast lets us call the constructor even though it's marked NS_UNAVAILABLE.
  NYPLRoundedButton *const button = [(id)self buttonWithType:UIButtonTypeSystem];
  
  button.titleLabel.font = [UIFont systemFontOfSize:14];
  button.layer.borderColor = button.tintColor.CGColor;
  button.layer.borderWidth = 1;
  button.layer.cornerRadius = 3;
  
  button.contentEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
  
  button.label = [UILabel new];
  button.label.textColor = button.tintColor;
  button.label.font = [UIFont systemFontOfSize:9];
  
  [button addSubview:button.label];
  
  return button;
}

- (void)updateColors
{
  UIColor *color = self.enabled ? self.tintColor : [UIColor grayColor];
  self.layer.borderColor = color.CGColor;
  self.label.textColor = color;
}

- (void)setEnabled:(BOOL)enabled
{
  [super setEnabled:enabled];
  [self updateColors];
}

#pragma mark UIView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
  if(!self.enabled && [self pointInside:[self convertPoint:point toView:self] withEvent:event]) {
    return self;
  }
  return [super hitTest:point withEvent:event];
}

- (CGSize)sizeThatFits:(CGSize const)size
{
  CGSize s = [super sizeThatFits:size];
  s.width += 16;
  return s;
}

- (void)tintColorDidChange
{
  [super tintColorDidChange];
  [self updateColors];
}

@end
