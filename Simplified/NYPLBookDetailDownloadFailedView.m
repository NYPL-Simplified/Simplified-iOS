#import "NYPLConfiguration.h"
#import "NYPLLinearView.h"
#import "NYPLRoundedButton.h"
#import "UIView+NYPLViewAdditions.h"

#import "NYPLBookDetailDownloadFailedView.h"

@interface NYPLBookDetailDownloadFailedView ()

@property (nonatomic) NYPLRoundedButton *cancelButton;
@property (nonatomic) NYPLLinearView *cancelTryAgainLinearView;
@property (nonatomic) UILabel *messageLabel;
@property (nonatomic) NYPLRoundedButton *tryAgainButton;

@end

@implementation NYPLBookDetailDownloadFailedView

- (instancetype)initWithWidth:(CGFloat)width
{
  self = [super initWithFrame:CGRectMake(0, 0, width, 70)];
  if(!self) return nil;
  
  self.backgroundColor = [UIColor grayColor];
  
  self.messageLabel = [[UILabel alloc] init];
  self.messageLabel.font = [UIFont systemFontOfSize:12];
  self.messageLabel.textColor = [NYPLConfiguration backgroundColor];
  self.messageLabel.text = NYPLLocalizedString(@"DownloadCouldNotBeCompleted", nil);
  [self addSubview:self.messageLabel];
  
  self.cancelButton = [NYPLRoundedButton button];
  [self.cancelButton setTitle:NYPLLocalizedString(@"Cancel", nil)
                     forState:UIControlStateNormal];
  [self.cancelButton addTarget:self
                        action:@selector(didSelectCancel)
              forControlEvents:UIControlEventTouchUpInside];
  self.cancelButton.backgroundColor = [NYPLConfiguration backgroundColor];
  self.cancelButton.tintColor = [UIColor grayColor];
  self.cancelButton.layer.borderWidth = 0;
  
  self.tryAgainButton = [NYPLRoundedButton button];
  [self.tryAgainButton setTitle:NYPLLocalizedString(@"TryAgain", nil)
                       forState:UIControlStateNormal];
  [self.tryAgainButton addTarget:self
                          action:@selector(didSelectTryAgain)
                forControlEvents:UIControlEventTouchUpInside];
  self.tryAgainButton.backgroundColor = [NYPLConfiguration backgroundColor];
  self.tryAgainButton.tintColor = [UIColor grayColor];
  self.tryAgainButton.layer.borderWidth = 0;
  
  self.cancelTryAgainLinearView = [[NYPLLinearView alloc] init];
  self.cancelTryAgainLinearView.padding = 5.0;
  [self.cancelTryAgainLinearView addSubview:self.cancelButton];
  [self.cancelTryAgainLinearView addSubview:self.tryAgainButton];
  [self addSubview:self.cancelTryAgainLinearView];
  
  return self;
}

#pragma mark UIView

- (void)layoutSubviews
{
  CGFloat const messageTopPadding = 9;
  CGFloat const buttonPadding = 5;
  
  [self.messageLabel sizeToFit];
  self.messageLabel.center = self.center;
  self.messageLabel.frame = CGRectMake(CGRectGetMinX(self.messageLabel.frame),
                                       messageTopPadding,
                                       CGRectGetWidth(self.messageLabel.frame),
                                       CGRectGetHeight(self.messageLabel.frame));
  [self.messageLabel integralizeFrame];
  
  [self.cancelButton sizeToFit];
  
  [self.tryAgainButton sizeToFit];
  
  [self.cancelTryAgainLinearView sizeToFit];
  self.cancelTryAgainLinearView.center = self.center;
  self.cancelTryAgainLinearView.frame =
    CGRectMake(CGRectGetMinX(self.cancelTryAgainLinearView.frame),
               (CGRectGetHeight(self.frame) -
                CGRectGetHeight(self.cancelTryAgainLinearView.frame) - buttonPadding),
               CGRectGetWidth(self.cancelTryAgainLinearView.frame),
               CGRectGetHeight(self.cancelTryAgainLinearView.frame));
  [self.cancelTryAgainLinearView integralizeFrame];
}

#pragma mark -

- (void)didSelectCancel
{
  [self.delegate didSelectCancelForBookDetailDownloadFailedView:self];
}

- (void)didSelectTryAgain
{
  [self.delegate didSelectTryAgainForBookDetailDownloadFailedView:self];
}

@end
