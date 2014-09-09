#import "NYPLConfiguration.h"
#import "NYPLRoundedButton.h"

#import "NYPLBookDetailDownloadingView.h"

@interface NYPLBookDetailDownloadingView ()

@property (nonatomic) NYPLRoundedButton *cancelButton;
@property (nonatomic) UILabel *downloadingLabel;
@property (nonatomic) UILabel *percentageLabel;
@property (nonatomic) UIProgressView *progressView;

@end

@implementation NYPLBookDetailDownloadingView

- (instancetype)initWithWidth:(CGFloat)width
{
  self = [super initWithFrame:CGRectMake(0, 0, width, 70)];
  if(!self) return nil;
  
  self.backgroundColor = [NYPLConfiguration mainColor];
  
  self.cancelButton = [NYPLRoundedButton button];
  [self.cancelButton setTitle:NSLocalizedString(@"Cancel", nil)
                     forState:UIControlStateNormal];
  [self.cancelButton addTarget:self
                        action:@selector(didSelectCancel)
              forControlEvents:UIControlEventTouchUpInside];
  self.cancelButton.backgroundColor = [NYPLConfiguration backgroundColor];
  self.cancelButton.tintColor = [NYPLConfiguration mainColor];
  self.cancelButton.layer.borderWidth = 0;
  [self addSubview:self.cancelButton];
  
  self.downloadingLabel = [[UILabel alloc] init];
  self.downloadingLabel.font = [UIFont systemFontOfSize:12];
  self.downloadingLabel.text = NSLocalizedString(@"Downloading", nil);
  self.downloadingLabel.textColor = [NYPLConfiguration backgroundColor];
  [self addSubview:self.downloadingLabel];
  
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
  CGFloat const downloadAreaTopPadding = 9;
  
  [self.downloadingLabel sizeToFit];
  self.downloadingLabel.frame = CGRectMake(sidePadding,
                                           downloadAreaTopPadding,
                                           CGRectGetWidth(self.downloadingLabel.frame),
                                           CGRectGetHeight(self.downloadingLabel.frame));
  
  NSString *const percentageLabelText = self.percentageLabel.text;
  self.percentageLabel.text = @"100%";
  [self.percentageLabel sizeToFit];
  self.percentageLabel.text = percentageLabelText;
  self.percentageLabel.frame = CGRectMake((CGRectGetWidth(self.frame) - sidePadding -
                                           CGRectGetWidth(self.percentageLabel.frame)),
                                          CGRectGetMinY(self.downloadingLabel.frame),
                                          CGRectGetWidth(self.percentageLabel.frame),
                                          CGRectGetHeight(self.percentageLabel.frame));
  
  self.progressView.center = self.downloadingLabel.center;
  self.progressView.frame = CGRectMake(CGRectGetMaxX(self.downloadingLabel.frame) + sidePadding,
                                       CGRectGetMinY(self.progressView.frame),
                                       (CGRectGetWidth(self.frame) - sidePadding * 4 -
                                        CGRectGetWidth(self.downloadingLabel.frame) -
                                        CGRectGetWidth(self.percentageLabel.frame)),
                                       CGRectGetHeight(self.progressView.frame));
  
  [self.cancelButton sizeToFit];
  self.cancelButton.center = self.center;
  self.cancelButton.frame = CGRectMake(CGRectGetMinX(self.cancelButton.frame),
                                       (CGRectGetHeight(self.frame) -
                                        CGRectGetHeight(self.cancelButton.frame) - 5),
                                       CGRectGetWidth(self.cancelButton.frame),
                                       CGRectGetHeight(self.cancelButton.frame));
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

- (void)didSelectCancel
{
  [self.delegate didSelectCancelForBookDetailDownloadingView:self];
}

@end
