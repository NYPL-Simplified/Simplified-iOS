#import "NYPLBook.h"
#import "NYPLBookDownloadFailedCell.h"
#import "NYPLConfiguration.h"
#import "NYPLRoundedButton.h"
#import "UIView+NYPLViewAdditions.h"

@interface NYPLBookDownloadFailedCell ()

@property (nonatomic) UILabel *authorsLabel;
@property (nonatomic) UIView *buttonContainerView;
@property (nonatomic) NYPLRoundedButton *cancelButton;
@property (nonatomic) UILabel *messageLabel;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) NYPLRoundedButton *tryAgainButton;

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
  
  [self.cancelButton sizeToFit];

  self.tryAgainButton.frame = CGRectMake(CGRectGetWidth(self.cancelButton.frame) + buttonPadding,
                                         0,
                                         0,
                                         0);
  [self.tryAgainButton sizeToFit];
  
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
  
  self.cancelButton = [NYPLRoundedButton button];
  self.cancelButton.backgroundColor = [NYPLConfiguration backgroundColor];
  self.cancelButton.tintColor = [UIColor grayColor];
  self.cancelButton.layer.borderWidth = 0;
  [self.cancelButton setTitle:NSLocalizedString(@"Cancel", nil)
                     forState:UIControlStateNormal];
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
  
  self.tryAgainButton = [NYPLRoundedButton button];
  self.tryAgainButton.backgroundColor = [NYPLConfiguration backgroundColor];
  self.tryAgainButton.tintColor = [UIColor grayColor];
  self.tryAgainButton.layer.borderWidth = 0;
  [self.tryAgainButton setTitle:NSLocalizedString(@"TryAgain", nil)
                       forState:UIControlStateNormal];
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
