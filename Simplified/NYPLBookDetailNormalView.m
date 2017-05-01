#import "NSDate+NYPLDateAdditions.h"
#import "NYPLBook.h"
#import "NYPLBookAcquisition.h"
#import "NYPLConfiguration.h"
#import "NYPLLinearView.h"
#import "NYPLBookButtonsView.h"
#import "UIView+NYPLViewAdditions.h"
#import "UIFont+NYPLSystemFontOverride.h"
#import <PureLayout/PureLayout.h>

#import "NYPLBookDetailNormalView.h"

@interface NYPLBookDetailNormalView ()

typedef NS_ENUM (NSInteger, NYPLProblemReportButtonState) {
  NYPLProblemReportButtonStateNormal,
  NYPLProblemReportButtonStateSent
};

@property (nonatomic) UIView *backgroundView;
@property (nonatomic) UILabel *messageLabel;

@end

@implementation NYPLBookDetailNormalView

#pragma mark UIView

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.backgroundView = [[UIView alloc] init];
  self.backgroundView.backgroundColor = [NYPLConfiguration mainColor];
  [self addSubview:self.backgroundView];
  [self.backgroundView autoPinEdgesToSuperviewEdges];
  
  self.messageLabel = [[UILabel alloc] init];
  self.messageLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
  self.messageLabel.textColor = [NYPLConfiguration backgroundColor];
  self.messageLabel.numberOfLines = 2;
  self.messageLabel.textAlignment = NSTextAlignmentCenter;
  [self addSubview:self.messageLabel];
  [self.messageLabel autoCenterInSuperview];
  [self.messageLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:12 relation:NSLayoutRelationGreaterThanOrEqual];
  [self.messageLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:12 relation:NSLayoutRelationGreaterThanOrEqual];
  [self.messageLabel autoPinEdgeToSuperviewMargin:ALEdgeTop relation:NSLayoutRelationGreaterThanOrEqual];
  [self.messageLabel autoPinEdgeToSuperviewMargin:ALEdgeBottom relation:NSLayoutRelationGreaterThanOrEqual];
  
  return self;
}

#pragma mark -

- (void)setState:(NYPLBookButtonsState const)state
{
  _state = state;
  
  NSString *newMessageString;
  switch(state) {
    case NYPLBookButtonsStateCanBorrow:
      newMessageString = NSLocalizedString(@"BookDetailViewControllerAvailableToBorrowTitle", nil);
      break;
    case NYPLBookButtonsStateCanHold:
      newMessageString = NSLocalizedString(@"BookDetailViewControllerCanHoldTitle", nil);
      break;
    case NYPLBookButtonsStateCanKeep:
      newMessageString = NSLocalizedString(@"BookDetailViewControllerCanKeepTitle", nil);
      break;
    case NYPLBookButtonsStateDownloadNeeded:
      newMessageString = NSLocalizedString(@"BookDetailViewControllerDownloadNeededTitle", nil);
      break;
    case NYPLBookButtonsStateDownloadSuccessful:
      newMessageString = NSLocalizedString(@"BookDetailViewControllerDownloadSuccessfulTitle", nil);
      break;
    case NYPLBookButtonsStateHolding:
      newMessageString = [NSString stringWithFormat:NSLocalizedString(@"BookDetailViewControllerHoldingTitleFormat", nil),
                                [self.book.availableUntil longTimeUntilString]];
      break;
    case NYPLBookButtonsStateHoldingFOQ:
      newMessageString = [NSString stringWithFormat:NSLocalizedString(@"BookDetailViewControllerReservedTitleFormat", nil),
                                [self.book.availableUntil longTimeUntilString]];
      break;
    case NYPLBookButtonsStateUsed:
      newMessageString = NSLocalizedString(@"BookDetailViewControllerDownloadSuccessfulTitle", nil);
      break;
    case NYPLBookButtonsStateDownloadInProgress:
      break;
  }
  
  if (!self.messageLabel.text) {
    self.messageLabel.text = newMessageString;
  } else {
    CGFloat duration = 0.3f;
    [UIView animateWithDuration:duration animations:^{
      self.messageLabel.alpha = 0.0f;
    } completion:^(__unused BOOL finished) {
      self.messageLabel.alpha = 0.0f;
      self.messageLabel.text = newMessageString;
      [UIView animateWithDuration:duration animations:^{
        self.messageLabel.alpha = 1.0f;
      } completion:^(__unused BOOL finished) {
        self.messageLabel.alpha = 1.0f;
      }];
    }];
  }
}

@end
