#import "NYPLRoundedButton.h"
#import "UIView+NYPLViewAdditions.h"

#import "NYPLReloadView.h"

@interface NYPLReloadView ()

@property (nonatomic) UILabel *messageLabel;
@property (nonatomic) NYPLRoundedButton *reloadButton;
@property (nonatomic) UILabel *titleLabel;

@end

static CGFloat const width = 250;

@implementation NYPLReloadView

#pragma mark NSObject

- (instancetype)init
{
  self = [super initWithFrame:CGRectMake(0, 0, width, 0)];
  if(!self) return nil;
  
  self.titleLabel = [[UILabel alloc] init];
  self.titleLabel.font = [UIFont boldSystemFontOfSize:17];
  self.titleLabel.text = NYPLLocalizedString(@"ConnectionFailed", nil);
  self.titleLabel.textColor = [UIColor grayColor];
  [self addSubview:self.titleLabel];
  
  self.messageLabel = [[UILabel alloc] init];
  self.messageLabel.numberOfLines = 2;
  self.messageLabel.textAlignment = NSTextAlignmentCenter;
  self.messageLabel.font = [UIFont systemFontOfSize:12];
  self.messageLabel.text = NYPLLocalizedString(@"CheckConnection", nil);
  self.messageLabel.textColor = [UIColor grayColor];
  [self addSubview:self.messageLabel];
  
  self.reloadButton = [NYPLRoundedButton button];
  [self.reloadButton setTitle:NYPLLocalizedString(@"TryAgain", nil)
                     forState:UIControlStateNormal];
  [self.reloadButton addTarget:self
                        action:@selector(didSelectReload)
              forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.reloadButton];
  
  [self layoutIfNeeded];
  
  self.frame = CGRectMake(0, 0, width, CGRectGetMaxY(self.reloadButton.frame));
  
  return self;
}

#pragma mark UIView

- (void)layoutSubviews
{
  CGFloat const padding = 5.0;
  
  {
    [self.titleLabel sizeToFit];
    [self.titleLabel centerInSuperview];
    [self.titleLabel integralizeFrame];
    CGRect frame = self.titleLabel.frame;
    frame.origin.y = 0;
    self.titleLabel.frame = frame;
  }
  
  {
    CGFloat h = [self.messageLabel sizeThatFits:
                 CGSizeMake(CGRectGetWidth(self.frame), CGFLOAT_MAX)].height;
    
    self.messageLabel.frame = CGRectMake(0,
                                         CGRectGetMaxY(self.titleLabel.frame) + padding,
                                         CGRectGetWidth(self.frame),
                                         h);
  }
  
  {
    [self.reloadButton sizeToFit];
    [self.reloadButton centerInSuperview];
    [self.reloadButton integralizeFrame];
    CGRect frame = self.reloadButton.frame;
    frame.origin.y = CGRectGetMaxY(self.messageLabel.frame) + padding;
    self.reloadButton.frame = frame;
  }
}

#pragma mark -

- (void)didSelectReload
{
  if(self.handler) self.handler();
}

@end
