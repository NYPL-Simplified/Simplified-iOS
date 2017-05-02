#import "NYPLConfiguration.h"
#import "NYPLLinearView.h"
#import "NYPLRoundedButton.h"
#import "UIView+NYPLViewAdditions.h"
#import <PureLayout/PureLayout.h>

#import "NYPLBookDetailDownloadFailedView.h"

@interface NYPLBookDetailDownloadFailedView ()

@property (nonatomic) NYPLRoundedButton *cancelButton;
@property (nonatomic) NYPLLinearView *cancelTryAgainLinearView;
@property (nonatomic) UILabel *messageLabel;
@property (nonatomic) NYPLRoundedButton *tryAgainButton;

@end

@implementation NYPLBookDetailDownloadFailedView

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.backgroundColor = [UIColor grayColor];
  
  self.messageLabel = [[UILabel alloc] init];
  self.messageLabel.font = [UIFont boldSystemFontOfSize:14];
  self.messageLabel.textAlignment = NSTextAlignmentCenter;
  self.messageLabel.textColor = [NYPLConfiguration backgroundColor];
  self.messageLabel.text = NSLocalizedString(@"DownloadCouldNotBeCompleted", nil);
  [self addSubview:self.messageLabel];
  [self.messageLabel autoPinEdgesToSuperviewEdges];
  
  return self;
}

@end
