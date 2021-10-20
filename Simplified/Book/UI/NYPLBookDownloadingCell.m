#import "NYPLBook.h"
#import "NYPLConfiguration.h"
#import "SimplyE-Swift.h"

#import "UIView+NYPLViewAdditions.h"
#import "NYPLLocalization.h"

#import "NYPLBookDownloadingCell.h"

@interface NYPLBookDownloadingCell ()

@property (nonatomic) UILabel *authorsLabel;
@property (nonatomic) NYPLRoundedButton *cancelButton;
@property (nonatomic) UILabel *downloadingLabel;
@property (nonatomic) UILabel *percentageLabel;
@property (nonatomic) UIProgressView *progressView;
@property (nonatomic) UILabel *titleLabel;

@end

@implementation NYPLBookDownloadingCell

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(setup)
                                               name:NSNotification.NYPLCurrentAccountDidChange
                                             object:nil];
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark UIView

- (void)layoutSubviews
{
  CGFloat const sidePadding = 10;
  CGFloat const downloadAreaTopPadding = 9;
  
  self.titleLabel.frame = CGRectMake(sidePadding,
                                     5,
                                     CGRectGetWidth([self contentFrame]) - sidePadding * 2,
                                     self.titleLabel.preferredHeight);
  
  self.authorsLabel.frame = CGRectMake(sidePadding,
                                       CGRectGetMaxY(self.titleLabel.frame),
                                       CGRectGetWidth([self contentFrame]) - sidePadding * 2,
                                       self.authorsLabel.preferredHeight);
  
  [self.downloadingLabel sizeToFit];
  self.downloadingLabel.frame = CGRectMake(sidePadding,
                                           (CGRectGetMaxY(self.authorsLabel.frame) +
                                            downloadAreaTopPadding),
                                           CGRectGetWidth(self.downloadingLabel.frame),
                                           CGRectGetHeight(self.downloadingLabel.frame));
  
  NSString *const percentageLabelText = self.percentageLabel.text;
  self.percentageLabel.text = NYPLLocalizationNotNeeded(@"100%");
  [self.percentageLabel sizeToFit];
  self.percentageLabel.text = percentageLabelText;
  self.percentageLabel.frame = CGRectMake((CGRectGetWidth([self contentFrame]) - sidePadding -
                                           CGRectGetWidth(self.percentageLabel.frame)),
                                          CGRectGetMinY(self.downloadingLabel.frame),
                                          CGRectGetWidth(self.percentageLabel.frame),
                                          CGRectGetHeight(self.percentageLabel.frame));
  
  self.progressView.center = self.downloadingLabel.center;
  self.progressView.frame = CGRectMake(CGRectGetMaxX(self.downloadingLabel.frame) + sidePadding,
                                       CGRectGetMinY(self.progressView.frame),
                                       (CGRectGetWidth([self contentFrame]) - sidePadding * 4 -
                                        CGRectGetWidth(self.downloadingLabel.frame) -
                                        CGRectGetWidth(self.percentageLabel.frame)),
                                       CGRectGetHeight(self.progressView.frame));
  [self.progressView integralizeFrame];
  
  [self.cancelButton sizeToFit];
  self.cancelButton.center = self.contentView.center;
  self.cancelButton.frame = CGRectMake(CGRectGetMinX(self.cancelButton.frame),
                                       (CGRectGetHeight([self contentFrame]) -
                                        CGRectGetHeight(self.cancelButton.frame) - 5),
                                       CGRectGetWidth(self.cancelButton.frame),
                                       CGRectGetHeight(self.cancelButton.frame));
  [self.cancelButton integralizeFrame];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
  [super traitCollectionDidChange:previousTraitCollection];
  
  if (@available(iOS 12.0, *)) {
    if (UIScreen.mainScreen.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle) {
      [self updateColors];
    }
  }
}

- (void)updateColors {
  self.backgroundColor = [NYPLConfiguration mainColor];
  if (@available(iOS 12.0, *)) {
    if (UIScreen.mainScreen.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
      self.backgroundColor = [NYPLConfiguration secondaryBackgroundColor];
    }
  }
}

#pragma mark -

- (void)setup
{
  self.authorsLabel = [[UILabel alloc] init];
  self.authorsLabel.font = [UIFont systemFontOfSize:12];
  self.authorsLabel.textColor = [NYPLConfiguration secondaryTextColor];
  [self.contentView addSubview:self.authorsLabel];
  
  self.cancelButton = [[NYPLRoundedButton alloc] initWithType:NYPLRoundedButtonTypeNormal isFromDetailView:NO];
  self.cancelButton.backgroundColor = [NYPLConfiguration primaryBackgroundColor];
  self.cancelButton.tintColor = [NYPLConfiguration primaryTextColor];
  self.cancelButton.layer.borderWidth = 0;
  [self.cancelButton setTitle:NSLocalizedString(@"Cancel", nil)
                     forState:UIControlStateNormal];
  [self.cancelButton addTarget:self
                        action:@selector(didSelectCancel)
              forControlEvents:UIControlEventTouchUpInside];
  [self.contentView addSubview:self.cancelButton];
  
  self.downloadingLabel = [[UILabel alloc] init];
  self.downloadingLabel.font = [UIFont systemFontOfSize:12];
  self.downloadingLabel.text = NSLocalizedString(@"Downloading", nil);
  self.downloadingLabel.textColor = [NYPLConfiguration secondaryTextColor];
  [self.contentView addSubview:self.downloadingLabel];
  
  self.percentageLabel = [[UILabel alloc] init];
  self.percentageLabel.font = [UIFont systemFontOfSize:12];
  self.percentageLabel.textColor = [NYPLConfiguration secondaryTextColor];
  self.percentageLabel.textAlignment = NSTextAlignmentRight;
  self.percentageLabel.text = NYPLLocalizationNotNeeded(@"0%");
  [self.contentView addSubview:self.percentageLabel];
  
  self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
  self.progressView.backgroundColor = [NYPLConfiguration progressBarBackgroundColor];
  self.progressView.tintColor = [NYPLConfiguration primaryBackgroundColor];
  [self.contentView addSubview:self.progressView];
  
  self.titleLabel = [[UILabel alloc] init];
  self.titleLabel.font = [UIFont boldSystemFontOfSize:17];
  self.titleLabel.textColor = [NYPLConfiguration secondaryTextColor];
  [self.contentView addSubview:self.titleLabel];
  
  [self updateColors];
}

- (void)setBook:(NYPLBook *const)book
{
  _book = book;
  
  if(!self.authorsLabel) {
    [self setup];
  }
  
  self.authorsLabel.text = book.authors;
  self.titleLabel.text = book.title;
  
  [self setNeedsLayout];
}

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
  [self.delegate didSelectCancelForBookDownloadingCell:self];
}

@end
