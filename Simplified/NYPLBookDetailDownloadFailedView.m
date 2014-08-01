#import "NYPLLinearView.h"

#import "NYPLBookDetailDownloadFailedView.h"

@interface NYPLBookDetailDownloadFailedView ()

@property (nonatomic) UIButton *cancelButton;
@property (nonatomic) NYPLLinearView *cancelTryAgainLinearView;
@property (nonatomic) UILabel *messageLabel;
@property (nonatomic) UIButton *tryAgainButton;

@end

@implementation NYPLBookDetailDownloadFailedView

- (instancetype)initWithWidth:(CGFloat)width
{
  self = [super initWithFrame:CGRectMake(0, 0, width, 70)];
  if(!self) return nil;
  
  self.backgroundColor = [UIColor grayColor];
  
  self.messageLabel = [[UILabel alloc] init];
  self.messageLabel.font = [UIFont systemFontOfSize:12];
  self.messageLabel.textColor = [UIColor whiteColor];
  self.messageLabel.text = NSLocalizedString(@"DownloadCouldNotBeCompleted", nil);
  [self addSubview:self.messageLabel];
  
  self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.cancelButton setTitle:NSLocalizedString(@"Cancel", nil)
                     forState:UIControlStateNormal];
  [self.cancelButton addTarget:self
                        action:@selector(didSelectCancel)
              forControlEvents:UIControlEventTouchUpInside];
  self.cancelButton.backgroundColor = [UIColor whiteColor];
  self.cancelButton.tintColor = [UIColor grayColor];
  self.cancelButton.layer.cornerRadius = 2;
  
  self.tryAgainButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.tryAgainButton setTitle:NSLocalizedString(@"TryAgain", nil)
                       forState:UIControlStateNormal];
  [self.tryAgainButton addTarget:self
                          action:@selector(didSelectTryAgain)
                forControlEvents:UIControlEventTouchUpInside];
  self.tryAgainButton.backgroundColor = [UIColor whiteColor];
  self.tryAgainButton.tintColor = [UIColor grayColor];
  self.tryAgainButton.layer.cornerRadius = 2;
  
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
  
  [self.cancelButton sizeToFit];
  self.cancelButton.frame = CGRectInset(self.cancelButton.frame, -8, 0);
  
  [self.tryAgainButton sizeToFit];
  self.tryAgainButton.frame = CGRectInset(self.tryAgainButton.frame, -8, 0);
  
  [self.cancelTryAgainLinearView sizeToFit];
  self.cancelTryAgainLinearView.center = self.center;
  self.cancelTryAgainLinearView.frame =
    CGRectMake(CGRectGetMinX(self.cancelTryAgainLinearView.frame),
               (CGRectGetHeight(self.frame) -
                CGRectGetHeight(self.cancelTryAgainLinearView.frame) - buttonPadding),
               CGRectGetWidth(self.cancelTryAgainLinearView.frame),
               CGRectGetHeight(self.cancelTryAgainLinearView.frame));
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
