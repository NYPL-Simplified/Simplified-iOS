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

@property (nonatomic) UILabel *messageLabel;

@end

@implementation NYPLBookDetailNormalView

#pragma mark UIView

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
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
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didChangePreferredContentSize)
                                               name:UIContentSizeCategoryDidChangeNotification
                                             object:nil];
  
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)drawRect:(__unused CGRect)rect
{
  //Inner drop-shadow
  CGRect bounds = [self bounds];
  CGContextRef context = UIGraphicsGetCurrentContext();

  CGMutablePathRef visiblePath = CGPathCreateMutable();
  CGPathMoveToPoint(visiblePath, NULL, bounds.origin.x, bounds.origin.y);
  CGPathAddLineToPoint(visiblePath, NULL, bounds.origin.x + bounds.size.width, bounds.origin.y);
  CGPathAddLineToPoint(visiblePath, NULL, bounds.origin.x + bounds.size.width, bounds.origin.y + bounds.size.height);
  CGPathAddLineToPoint(visiblePath, NULL, bounds.origin.x, bounds.origin.y + bounds.size.height);
  CGPathAddLineToPoint(visiblePath, NULL, bounds.origin.x, bounds.origin.y);
  CGPathCloseSubpath(visiblePath);
  
  UIColor *aColor = [NYPLConfiguration mainColor];
  [aColor setFill];
  CGContextAddPath(context, visiblePath);
  CGContextFillPath(context);
  
  CGMutablePathRef path = CGPathCreateMutable();
  CGPathAddRect(path, NULL, CGRectInset(bounds, -42, -42));
  CGPathAddPath(path, NULL, visiblePath);
  CGPathCloseSubpath(path);
  CGContextAddPath(context, visiblePath);
  CGContextClip(context);
  
  aColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.5f];
  CGContextSaveGState(context);
  CGContextSetShadowWithColor(context, CGSizeMake(0.0f, 0.0f), 5.0f, [aColor CGColor]);
  [aColor setFill];
  CGContextSaveGState(context);
  CGContextAddPath(context, path);
  CGContextEOFillPath(context);
  CGPathRelease(path);
  CGPathRelease(visiblePath);
}

- (void)didChangePreferredContentSize
{
  self.messageLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleCaption1 multiplier:1.2];
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
    default:
      newMessageString = nil;
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
