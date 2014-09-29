#import "NYPLRoundedButton.h"
#import "UIView+NYPLViewAdditions.h"

#import "NYPLReloadLargeView.h"

@interface NYPLReloadLargeView ()

@property (nonatomic) UILabel *messageLabel;
@property (nonatomic) NYPLRoundedButton *reloadButton;
@property (nonatomic) UILabel *titleLabel;

@end

@implementation NYPLReloadLargeView

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.titleLabel = [[UILabel alloc] init];
  self.titleLabel.font = [UIFont systemFontOfSize:17];
  self.titleLabel.text = NSLocalizedString(@"ReloadLargeViewTitle", nil);
  [self addSubview:self.titleLabel];
  
  self.messageLabel = [[UILabel alloc] init];
  self.messageLabel.numberOfLines = 2;
  self.messageLabel.font = [UIFont systemFontOfSize:12];
  self.messageLabel.text = NSLocalizedString(@"ReloadLargeViewMessage", nil);
  [self addSubview:self.messageLabel];
  
  self.reloadButton = [NYPLRoundedButton button];
  self.reloadButton.titleLabel.text = NSLocalizedString(@"TryAgain", nil);
  [self.reloadButton addTarget:self
                        action:@selector(didSelectReload)
              forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.reloadButton];
  
  
  return self;
}

#pragma mark UIView

- (void)layoutSubviews
{
  CGFloat const padding = 5.0;
  
  {
    [self.titleLabel sizeToFit];
    self.titleLabel.center = self.center;
    [self.titleLabel integralizeFrame];
    CGRect frame = self.titleLabel.frame;
    frame.origin.y = padding;
    self.titleLabel.frame = frame;
  }
  
  {
    [self.messageLabel sizeToFit];
    self.messageLabel.center = self.center;
    [self.messageLabel integralizeFrame];
    CGRect frame = self.messageLabel.frame;
    frame.origin.y = CGRectGetMaxY(self.titleLabel.frame) + padding;
    self.messageLabel.frame = frame;
  }
  
  {
    [self.reloadButton sizeToFit];
    self.reloadButton.center = self.center;
    [self.reloadButton integralizeFrame];
    CGRect frame = self.reloadButton.frame;
    frame.origin.y = CGRectGetMaxY(self.messageLabel.frame) + padding;
    self.reloadButton.frame = frame;
  }
}

#pragma mark -

- (void)didSelectReload
{
  self.handler();
}

@end
