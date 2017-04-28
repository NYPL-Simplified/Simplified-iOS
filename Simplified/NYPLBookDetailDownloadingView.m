#import "NYPLConfiguration.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLRoundedButton.h"
#import "UIView+NYPLViewAdditions.h"

#import "NYPLBookDetailDownloadingView.h"

@interface NYPLBookDetailDownloadingView ()

@property (nonatomic) NYPLRoundedButton *cancelButton;
@property (nonatomic) UIView *backgroundView;
@property (nonatomic) UILabel *progressLabel;
@property (nonatomic) UILabel *percentageLabel;
@property (nonatomic) UIProgressView *progressView;

@end

@implementation NYPLBookDetailDownloadingView

- (instancetype)initWithWidth:(CGFloat)width
{
  self = [super initWithFrame:CGRectMake(0, 0, width, 70)];
  if(!self) return nil;
  
  self.backgroundView = [[UIView alloc] init];
  self.backgroundView.backgroundColor = [NYPLConfiguration mainColor];
  [self addSubview:self.backgroundView];
  
  self.cancelButton = [NYPLRoundedButton button];
  [self.cancelButton setTitle:NSLocalizedString(@"Cancel", nil)
                     forState:UIControlStateNormal];
  [self.cancelButton addTarget:self
                        action:@selector(didSelectCancel)
              forControlEvents:UIControlEventTouchUpInside];
  self.cancelButton.backgroundColor = [NYPLConfiguration backgroundColor];
  self.cancelButton.tintColor = [NYPLConfiguration mainColor];
  [self addSubview:self.cancelButton];
  
  self.progressLabel = [[UILabel alloc] init];
  self.progressLabel.font = [UIFont systemFontOfSize:12];
  self.progressLabel.text = NSLocalizedString(@"Requesting", nil);
  self.progressLabel.textColor = [NYPLConfiguration backgroundColor];
  [self addSubview:self.progressLabel];
  
  self.percentageLabel = [[UILabel alloc] init];
  self.percentageLabel.font = [UIFont systemFontOfSize:12];
  self.percentageLabel.textColor = [NYPLConfiguration backgroundColor];
  self.percentageLabel.textAlignment = NSTextAlignmentRight;
  self.percentageLabel.text = @"0%";
  [self addSubview:self.percentageLabel];
  
  self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
  self.progressView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
  self.progressView.tintColor = [NYPLConfiguration backgroundColor];
  [self addSubview:self.progressView];
  
  return self;
}

#pragma mark UIView

- (void)layoutSubviews
{
  CGFloat const sidePadding = 10;
  
  self.backgroundView.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), 60);
  
  [self.progressLabel sizeToFit];
  self.progressLabel.center = CGPointMake(self.backgroundView.center.x, 15);
  self.progressLabel.frame = CGRectMake(sidePadding,
                                        CGRectGetMinY(self.progressLabel.frame),
                                        CGRectGetWidth(self.progressLabel.frame),
                                        CGRectGetHeight(self.progressLabel.frame));
  
  NSString *const percentageLabelText = self.percentageLabel.text;
  self.percentageLabel.text = @"100%";
  [self.percentageLabel sizeToFit];
  self.percentageLabel.text = percentageLabelText;
  self.percentageLabel.frame = CGRectMake((CGRectGetWidth(self.frame) - sidePadding -
                                           CGRectGetWidth(self.percentageLabel.frame)),
                                          CGRectGetMinY(self.progressLabel.frame),
                                          CGRectGetWidth(self.percentageLabel.frame),
                                          CGRectGetHeight(self.percentageLabel.frame));
  
  self.progressView.center = self.progressLabel.center;
  self.progressView.frame = CGRectMake(CGRectGetMaxX(self.progressLabel.frame) + sidePadding,
                                       CGRectGetMinY(self.progressView.frame),
                                       (CGRectGetWidth(self.frame) - sidePadding * 4 -
                                        CGRectGetWidth(self.progressLabel.frame) -
                                        CGRectGetWidth(self.percentageLabel.frame)),
                                       CGRectGetHeight(self.progressView.frame));
  [self.progressView integralizeFrame];
  
  [self.cancelButton sizeToFit];
  self.cancelButton.center = self.center;
  self.cancelButton.frame = CGRectMake(CGRectGetMinX(self.cancelButton.frame),
                                       (CGRectGetHeight(self.frame) -
                                        CGRectGetHeight(self.cancelButton.frame) - 6),
                                       CGRectGetWidth(self.cancelButton.frame),
                                       CGRectGetHeight(self.cancelButton.frame));
  [self.cancelButton integralizeFrame];
}

#pragma mark -

- (double)downloadProgress
{
  return self.progressView.progress;
}

- (void)setDownloadProgress:(double const)downloadProgress
{
  self.progressView.progress = downloadProgress;
  
  self.percentageLabel.text = [NSString stringWithFormat:@"%d%%", (int) (downloadProgress * 100)];
}

- (void)setDownloadStarted:(BOOL)downloadStarted
{
  _downloadStarted = downloadStarted;
  NSString *status = downloadStarted ? @"Downloading" : @"Requesting";
  self.progressLabel.text = NSLocalizedString(status, nil);
  [self setNeedsLayout];
}

- (void)didSelectCancel
{
  [self.delegate didSelectCancelForBookDetailDownloadingView:self];
}

@end
