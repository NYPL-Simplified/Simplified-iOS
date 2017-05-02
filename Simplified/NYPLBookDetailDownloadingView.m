#import "NYPLConfiguration.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLRoundedButton.h"
#import "UIView+NYPLViewAdditions.h"
#import <PureLayout/PureLayout.h>

#import "NYPLBookDetailDownloadingView.h"

@interface NYPLBookDetailDownloadingView ()

@property (nonatomic) UIView *backgroundView;
@property (nonatomic) UILabel *progressLabel;
@property (nonatomic) UILabel *percentageLabel;
@property (nonatomic) UIProgressView *progressView;

@end

@implementation NYPLBookDetailDownloadingView

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  CGFloat const sidePadding = 10;
  
  self.translatesAutoresizingMaskIntoConstraints = NO;
  
  self.backgroundView = [[UIView alloc] init];
  self.backgroundView.backgroundColor = [NYPLConfiguration mainColor];
  [self addSubview:self.backgroundView];
  [self.backgroundView autoPinEdgesToSuperviewEdges];
  
  self.progressLabel = [[UILabel alloc] init];
  self.progressLabel.font = [UIFont systemFontOfSize:14];
  self.progressLabel.text = NSLocalizedString(@"Requesting", nil);
  self.progressLabel.textColor = [NYPLConfiguration backgroundColor];
  [self addSubview:self.progressLabel];
  [self.progressLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
  [self.progressLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:sidePadding];
  
  self.percentageLabel = [[UILabel alloc] init];
  self.percentageLabel.font = [UIFont systemFontOfSize:14];
  self.percentageLabel.textColor = [NYPLConfiguration backgroundColor];
  self.percentageLabel.textAlignment = NSTextAlignmentRight;
  self.percentageLabel.text = @"0%";
  [self addSubview:self.percentageLabel];
  [self.percentageLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
  [self.percentageLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:sidePadding];
  
  
  self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
  self.progressView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
  self.progressView.tintColor = [NYPLConfiguration backgroundColor];
  [self addSubview:self.progressView];
  [self.progressView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
  [self.progressView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.progressLabel withOffset:sidePadding*2];
  [self.progressView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.percentageLabel withOffset:-sidePadding*2];
  
  return self;
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

@end
