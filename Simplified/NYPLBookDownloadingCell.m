#import "NYPLBook.h"
#import "NYPLConfiguration.h"
#import "UIView+NYPLViewAdditions.h"

#import "NYPLBookDownloadingCell.h"

@interface NYPLBookDownloadingCell ()

@property (nonatomic) UILabel *authorsLabel;
@property (nonatomic) UIButton *cancelButton;
@property (nonatomic) UILabel *downloadingLabel;
@property (nonatomic) UILabel *percentageLabel;
@property (nonatomic) UIProgressView *progressView;
@property (nonatomic) UILabel *titleLabel;

@end

@implementation NYPLBookDownloadingCell

#pragma mark UIView

- (void)layoutSubviews
{
  CGFloat const sidePadding = 10;
  
  self.titleLabel.frame = CGRectMake(sidePadding,
                                     5,
                                     CGRectGetWidth(self.frame) - sidePadding * 2,
                                     self.titleLabel.preferredHeight);
  
  self.authorsLabel.frame = CGRectMake(sidePadding,
                                       CGRectGetMaxY(self.titleLabel.frame),
                                       CGRectGetWidth(self.frame) - sidePadding * 2,
                                       self.authorsLabel.preferredHeight);
  
  [self.downloadingLabel sizeToFit];
  self.downloadingLabel.frame = CGRectMake(sidePadding,
                                           CGRectGetMaxY(self.authorsLabel.frame) + 20,
                                           CGRectGetWidth(self.downloadingLabel.frame),
                                           CGRectGetHeight(self.downloadingLabel.frame));
  
  NSString *const percentageLabelText = self.percentageLabel.text;
  self.percentageLabel.text = @"00%";
  [self.percentageLabel sizeToFit];
  self.percentageLabel.frame = CGRectMake((CGRectGetWidth(self.frame) - sidePadding -
                                           CGRectGetWidth(self.percentageLabel.frame)),
                                          CGRectGetMinY(self.downloadingLabel.frame),
                                          CGRectGetWidth(self.percentageLabel.frame),
                                          CGRectGetHeight(self.percentageLabel.frame));
  self.percentageLabel.text = percentageLabelText;
  
  self.progressView.center = self.downloadingLabel.center;
  self.progressView.frame = CGRectMake(CGRectGetMaxX(self.downloadingLabel.frame) + sidePadding,
                                       CGRectGetMinY(self.progressView.frame),
                                       (CGRectGetWidth(self.frame) - sidePadding * 4 -
                                        CGRectGetWidth(self.downloadingLabel.frame) -
                                        CGRectGetWidth(self.percentageLabel.frame)),
                                       CGRectGetHeight(self.progressView.frame));
  
  [self.cancelButton sizeToFit];
  self.cancelButton.frame = CGRectInset(self.cancelButton.frame, -8, 0);
  self.cancelButton.center = self.center;
  self.cancelButton.frame = CGRectMake(CGRectGetMinX(self.cancelButton.frame),
                                       (CGRectGetHeight(self.frame) -
                                        CGRectGetHeight(self.cancelButton.frame) - 5),
                                       CGRectGetWidth(self.cancelButton.frame),
                                       CGRectGetHeight(self.cancelButton.frame));
}

#pragma mark -

- (void)setup
{
  self.backgroundColor = [NYPLConfiguration mainColor];
  
  self.authorsLabel = [[UILabel alloc] init];
  self.authorsLabel.font = [UIFont systemFontOfSize:12];
  self.authorsLabel.textColor = [UIColor whiteColor];
  [self addSubview:self.authorsLabel];
  
  self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
  self.cancelButton.backgroundColor = [UIColor whiteColor];
  [self.cancelButton setTitle:NSLocalizedString(@"Cancel", nil)
                     forState:UIControlStateNormal];
  self.cancelButton.layer.cornerRadius = 2;
  [self addSubview:self.cancelButton];
  
  self.downloadingLabel = [[UILabel alloc] init];
  self.downloadingLabel.font = [UIFont systemFontOfSize:12];
  self.downloadingLabel.text = NSLocalizedString(@"NYPLBookDownloadingCellDownloading", nil);
  self.downloadingLabel.textColor = [UIColor whiteColor];
  [self addSubview:self.downloadingLabel];
  
  self.percentageLabel = [[UILabel alloc] init];
  self.percentageLabel.font = [UIFont systemFontOfSize:12];
  self.percentageLabel.textColor = [UIColor whiteColor];
  self.percentageLabel.textAlignment = NSTextAlignmentRight;
  self.percentageLabel.text = @"0%";
  [self addSubview:self.percentageLabel];
  
  self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
  self.progressView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
  self.progressView.tintColor = [UIColor whiteColor];
  [self addSubview:self.progressView];
  
  self.titleLabel = [[UILabel alloc] init];
  self.titleLabel.font = [UIFont boldSystemFontOfSize:17];
  self.titleLabel.textColor = [UIColor whiteColor];
  [self addSubview:self.titleLabel];
}

- (void)setBook:(NYPLBook *const)book
{
  _book = book;
  
  if(!self.authorsLabel) {
    [self setup];
  }
  
  self.authorsLabel.text = book.authors;
  self.titleLabel.text = book.title;
}

- (void)setDownloadProgress:(double const)downloadProgress
{
  _downloadProgress = downloadProgress;
  
  self.progressView.progress = downloadProgress;
  self.percentageLabel.text = [NSString stringWithFormat:@"%d%%", (int) (downloadProgress * 100)];
}

@end
