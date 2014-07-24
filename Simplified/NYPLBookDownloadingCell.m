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
  
  self.progressView.frame = CGRectMake(CGRectGetMaxX(self.downloadingLabel.frame) + sidePadding,
                                       CGRectGetMinY(self.downloadingLabel.frame) + 1,
                                       (CGRectGetWidth(self.frame) - sidePadding * 4 -
                                        CGRectGetMaxX(self.downloadingLabel.frame)),
                                       CGRectGetHeight(self.progressView.frame));
                                       
                                     
}

#pragma mark -

- (void)setup
{
  self.backgroundColor = [NYPLConfiguration mainColor];
  
  self.authorsLabel = [[UILabel alloc] init];
  self.authorsLabel.font = [UIFont systemFontOfSize:12];
  self.authorsLabel.textColor = [UIColor whiteColor];
  [self addSubview:self.authorsLabel];
  
  self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.cancelButton.backgroundColor = [UIColor whiteColor];
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
  [self addSubview:self.percentageLabel];
  
  self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
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

@end
