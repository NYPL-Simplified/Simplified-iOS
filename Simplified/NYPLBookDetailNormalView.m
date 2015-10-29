#import "NSDate+NYPLDateAdditions.h"
#import "NYPLBook.h"
#import "NYPLConfiguration.h"
#import "NYPLLinearView.h"
#import "NYPLBookButtonsView.h"
#import "UIView+NYPLViewAdditions.h"

#import "NYPLBookDetailNormalView.h"

@interface NYPLBookDetailNormalView ()

@property (nonatomic) UIView *backgroundView;
@property (nonatomic) UILabel *messageLabel;
@property (nonatomic) NYPLBookButtonsView *buttonsView;
@property (nonatomic) UIButton *reportAProblemButton;

@end

@implementation NYPLBookDetailNormalView

#pragma mark UIView

- (instancetype)initWithWidth:(CGFloat)width
{
  self = [super initWithFrame:CGRectMake(0, 0, width, 70)];
  if(!self) return nil;
  
  self.backgroundView = [[UIView alloc] init];
  self.backgroundView.backgroundColor = [NYPLConfiguration mainColor];
  [self addSubview:self.backgroundView];
  
  self.buttonsView = [[NYPLBookButtonsView alloc] init];
  [self addSubview:self.buttonsView];
  
  self.reportAProblemButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.reportAProblemButton setTitle:NSLocalizedString(@"Report a Problem", nil) forState:UIControlStateNormal];
  [self.reportAProblemButton.titleLabel setFont:[UIFont systemFontOfSize:12.0]];
  [self.reportAProblemButton addTarget:self action:@selector(reportAProblem:) forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.reportAProblemButton];
  
  self.messageLabel = [[UILabel alloc] init];
  self.messageLabel.font = [UIFont systemFontOfSize:12];
  self.messageLabel.textColor = [NYPLConfiguration backgroundColor];
  [self addSubview:self.messageLabel];
  
  return self;
}

- (void)sizeToFit
{
  CGRect frame = self.frame;
  frame.size.height = CGRectGetMaxY(self.buttonsView.frame);
  self.frame = frame;
}

- (void)reportAProblem:(id)sender
{
  [self.delegate didSelectReportForBook:self.book sender:sender];
}

#pragma mark UIView

- (void)layoutSubviews
{
  CGFloat padding = 10;
  
  self.backgroundView.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), 30);
  CGFloat nextY = CGRectGetMaxY(self.backgroundView.frame) + padding;
  
  [self.messageLabel sizeToFit];
  self.messageLabel.center = self.backgroundView.center;
  [self.messageLabel integralizeFrame];
  
  [self.buttonsView sizeToFit];
  self.buttonsView.center = self.center;
  self.buttonsView.frame = CGRectMake(CGRectGetMinX(self.buttonsView.frame),
                                      nextY,
                                      CGRectGetWidth(self.buttonsView.frame),
                                      CGRectGetHeight(self.buttonsView.frame));
  [self.buttonsView integralizeFrame];
  
  [self.reportAProblemButton sizeToFit];
  self.reportAProblemButton.center = CGPointMake(self.bounds.size.width - self.reportAProblemButton.bounds.size.width/2.0 - 17.0, self.buttonsView.center.y);
  [self.reportAProblemButton integralizeFrame];
}

#pragma mark -

- (void)setState:(NYPLBookButtonsState const)state
{
  _state = state;
  self.buttonsView.state = state;
  
  switch(state) {
    case NYPLBookButtonsStateCanBorrow:
      self.messageLabel.text = NSLocalizedString(@"BookDetailViewControllerAvailableToBorrowTitle", nil);
      break;
    case NYPLBookButtonsStateCanHold:
      self.messageLabel.text = NSLocalizedString(@"BookDetailViewControllerCanHoldTitle", nil);
      break;
    case NYPLBookButtonsStateCanKeep:
      self.messageLabel.text = NSLocalizedString(@"BookDetailViewControllerCanKeepTitle", nil);
      break;
    case NYPLBookButtonsStateDownloadNeeded:
      self.messageLabel.text = NSLocalizedString(@"BookDetailViewControllerDownloadNeededTitle", nil);
      break;
    case NYPLBookButtonsStateDownloadSuccessful:
      self.messageLabel.text = NSLocalizedString(@"BookDetailViewControllerDownloadSuccessfulTitle", nil);
      break;
    case NYPLBookButtonsStateHolding:
      self.messageLabel.text = [NSString stringWithFormat:NSLocalizedString(@"BookDetailViewControllerHoldingTitleFormat", nil),
                                [self.book.availableUntil longTimeUntilString]];
      break;
    case NYPLBookButtonsStateHoldingFOQ:
      self.messageLabel.text = [NSString stringWithFormat:NSLocalizedString(@"BookDetailViewControllerReservedTitleFormat", nil),
                                [self.book.availableUntil longTimeUntilString]];
      break;
    case NYPLBookButtonsStateUsed:
      self.messageLabel.text = NSLocalizedString(@"BookDetailViewControllerDownloadSuccessfulTitle", nil);
      break;
  }
  
  [self.messageLabel sizeToFit];
  self.messageLabel.center = self.backgroundView.center;
  [self.messageLabel integralizeFrame];
}

- (void)setDelegate:(id<NYPLBookButtonsDelegate>)delegate
{
  _delegate = delegate;
  self.buttonsView.delegate = delegate;
}

- (void)setBook:(NYPLBook *)book
{
  _book = book;
  self.buttonsView.book = book;
}

@end
