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
  
  button.titleLabel.font = [UIFont systemFontOfSize:12];
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

- (void)setQueuePosition:(NSInteger)queuePosition
{
  _queuePosition = queuePosition;
  [self updateViews];
}

- (void)setEndDate:(NSDate *)endDate
{
  _endDate = endDate;
  [self updateViews];
}

- (void)updateViews
{
  if (self.type == NYPLRoundedButtonTypeNormal) {
    self.contentEdgeInsets = UIEdgeInsetsZero;
    self.iconView.hidden = YES;
    self.label.hidden = YES;
  } else {
    NSString *imageName = self.type == NYPLRoundedButtonTypeClock ? @"Clock" : @"Clock"; // TODO: get queue icon
    self.iconView.image = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.iconView.hidden = NO;
    self.label.hidden = NO;
    if (self.type == NYPLRoundedButtonTypeClock) {
      self.label.text = [self.endDate shortTimeUntilString];
    } else {
      self.label.text = [@(self.queuePosition) stringValue];
    }
    
    [self.label sizeToFit];
    
    self.iconView.frame = CGRectMake(8, 3, 14, 14);
    CGRect frame = self.label.frame;
    frame.origin = CGPointMake(self.iconView.center.x - frame.size.width/2, CGRectGetMaxY(self.iconView.frame));
    self.label.frame = frame;
    self.contentEdgeInsets = UIEdgeInsetsMake(6, self.iconView.frame.size.width + 8, 6, 0);
  }
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
  self.label.textColor = self.tintColor;
}

@end
