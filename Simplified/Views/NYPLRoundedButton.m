@import PureLayout;

#import "NYPLRoundedButton.h"
#import "NSDate+NYPLDateAdditions.h"

@interface NYPLRoundedButton ()

@property (nonatomic) UIImageView *iconView;
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
  
  button.iconView = [UIImageView new];
  button.label = [UILabel new];
  button.label.textColor = button.tintColor;
  button.label.font = [UIFont systemFontOfSize:9];
  
  [button addSubview:button.iconView];
  [button addSubview:button.label];
  
  button.type = NYPLRoundedButtonTypeNormal;

  return button;
}

- (void)setType:(NYPLRoundedButtonType)type
{
  _type = type;
  [self updateViews];
}

- (void)setEndDate:(NSDate *)endDate
{
  _endDate = endDate;
  [self updateViews];
}

- (void)updateViews
{
  if(self.type == NYPLRoundedButtonTypeNormal || self.fromDetailView) {
    if (!self.fromDetailView) {
      self.contentEdgeInsets = UIEdgeInsetsZero;
    } else {
      self.contentEdgeInsets = UIEdgeInsetsMake(8, 20, 8, 20);
    }
    self.iconView.hidden = YES;
    self.label.hidden = YES;
  } else {
    self.iconView.image = [[UIImage imageNamed:@"Clock"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.iconView.hidden = NO;
    self.label.hidden = NO;
    self.label.text = [self.endDate shortTimeUntilString];
    [self.label sizeToFit];

    self.iconView.frame = CGRectMake(8, 3, 14, 14);
    CGRect frame = self.label.frame;
    frame.origin = CGPointMake(self.iconView.center.x - frame.size.width/2, CGRectGetMaxY(self.iconView.frame));
    self.label.frame = frame;
    self.contentEdgeInsets = UIEdgeInsetsMake(6, self.iconView.frame.size.width + 8, 6, 0);
  }
}

- (void)updateColors
{
  UIColor *color = self.enabled ? self.tintColor : [UIColor grayColor];
  self.layer.borderColor = color.CGColor;
  self.label.textColor = color;
  self.iconView.tintColor = color;
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

- (NSString *)accessibilityLabel
{
  if (self.iconView.isHidden) {
    return self.titleLabel.text;
  } else {
    NSString *timeString = [self.endDate longTimeUntilString];
    return [NSString stringWithFormat:@"%@. %@ remaining.", self.titleLabel.text, timeString];
  }
}

@end
