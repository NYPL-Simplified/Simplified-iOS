#import "NYPLBook.h"
#import "NYPLBookDownloadFailedCell.h"
#import "NYPLConfiguration.h"
#import "UIView+NYPLViewAdditions.h"

@interface NYPLBookDownloadFailedCell ()

@property (nonatomic) UILabel *authorsLabel;
@property (nonatomic) UIView *buttonContainerView;
@property (nonatomic) UIButton *cancelButton;
@property (nonatomic) UILabel *messageLabel;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIButton *tryAgainButton;

@end

@implementation NYPLBookDownloadFailedCell

#pragma mark UIView

- (void)layoutSubviews
{
  CGFloat const sidePadding = 10;
  CGFloat const messageTopPadding = 9;
  CGFloat const buttonPadding = 5;
  
  self.titleLabel.frame = CGRectMake(sidePadding,
                                     5,
                                     CGRectGetWidth([self contentFrame]) - sidePadding * 2,
                                     self.titleLabel.preferredHeight);
  
  self.authorsLabel.frame = CGRectMake(sidePadding,
                                       CGRectGetMaxY(self.titleLabel.frame),
                                       CGRectGetWidth([self contentFrame]) - sidePadding * 2,
                                       self.authorsLabel.preferredHeight);
  
  [self.messageLabel sizeToFit];
  self.messageLabel.frame = CGRectMake(sidePadding,
                                       (CGRectGetMaxY(self.authorsLabel.frame) +
                                        messageTopPadding),
                                       CGRectGetWidth([self contentFrame]) - sidePadding * 2,
                                       CGRectGetHeight(self.messageLabel.frame));
  
  self.cancelButton.frame = CGRectMake(8, 0, 0, 0);
  [self.cancelButton sizeToFit];
  self.cancelButton.frame = CGRectInset(self.cancelButton.frame, -8, 0);
  
  self.tryAgainButton.frame = CGRectMake(CGRectGetWidth(self.cancelButton.frame) + buttonPadding + 8,
                                         0,
                                         0,
                                         0);
  [self.tryAgainButton sizeToFit];
  self.tryAgainButton.frame = CGRectInset(self.tryAgainButton.frame, -8, 0);
  
  CGFloat const buttonContainerViewWidth =
    (CGRectGetWidth(self.cancelButton.frame) +
     CGRectGetWidth(self.tryAgainButton.frame) +
     buttonPadding);
  
  self.buttonContainerView.frame = CGRectMake((CGRectGetWidth([self contentFrame]) / 2 -
                                               buttonContainerViewWidth / 2),
                                              (CGRectGetHeight([self contentFrame]) -
                                               CGRectGetHeight(self.cancelButton.frame) -
                                               buttonPadding),
                                              buttonContainerViewWidth,
                                              CGRectGetHeight(self.cancelButton.frame));
}

#pragma mark -

- (void)setup
{
  self.backgroundColor = [UIColor grayColor];
  
  self.authorsLabel = [[UILabel alloc] init];
  self.authorsLabel.font = [UIFont systemFontOfSize:12];
  self.authorsLabel.textColor = [NYPLConfiguration backgroundColor];
  [self.contentView addSubview:self.authorsLabel];
  
  self.buttonContainerView = [[UIView alloc] init];
  [self.contentView addSubview:self.buttonContainerView];
  
  self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
  self.cancelButton.backgroundColor = [NYPLConfiguration backgroundColor];
  self.cancelButton.tintColor = [UIColor grayColor];
  [self.cancelButton setTitle:NSLocalizedString(@"Cancel", nil)
                     forState:UIControlStateNormal];
  self.cancelButton.layer.cornerRadius = 2;
  [self.cancelButton addTarget:self
                        action:@selector(didSelectCancel)
              forControlEvents:UIControlEventTouchUpInside];
  [self.buttonContainerView addSubview:self.cancelButton];
  
  self.messageLabel = [[UILabel alloc] init];
  self.messageLabel.font = [UIFont systemFontOfSize:12];
  self.messageLabel.textColor = [NYPLConfiguration backgroundColor];
  self.messageLabel.text = NSLocalizedString(@"DownloadCouldNotBeCompleted", nil);
  self.messageLabel.textAlignment = NSTextAlignmentCenter;
  [self.contentView addSubview:self.messageLabel];
  
  self.titleLabel = [[UILabel alloc] init];
  self.titleLabel.font = [UIFont boldSystemFontOfSize:17];
  self.titleLabel.textColor = [NYPLConfiguration backgroundColor];
  [self.contentView addSubview:self.titleLabel];
  
  self.tryAgainButton = [UIButton buttonWithType:UIButtonTypeSystem];
  self.tryAgainButton.backgroundColor = [NYPLConfiguration backgroundColor];
  self.tryAgainButton.tintColor = [UIColor grayColor];
  [self.tryAgainButton setTitle:NSLocalizedString(@"TryAgain", nil)
                       forState:UIControlStateNormal];
  self.tryAgainButton.layer.cornerRadius = 2;
  [self.tryAgainButton addTarget:self
                          action:@selector(didSelectTryAgain)
                forControlEvents:UIControlEventTouchUpInside];
  [self.buttonContainerView addSubview:self.tryAgainButton];
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

- (void)didSelectCancel
{
  [self.delegate didSelectCancelForBookDownloadFailedCell:self];
}

- (void)didSelectTryAgain
{
  [self.delegate didSelectTryAgainForBookDownloadFailedCell:self];
}

@end
