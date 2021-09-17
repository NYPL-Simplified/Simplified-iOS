@import PureLayout;
#import "SimplyE-Swift.h"

#import "NYPLConfiguration.h"
#import "NYPLLinearView.h"
#import "UIView+NYPLViewAdditions.h"
#import "UIFont+NYPLSystemFontOverride.h"
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
  
  self.backgroundColor = [NYPLConfiguration mainColor];
  
  self.messageLabel = [[UILabel alloc] init];
  self.messageLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
  self.messageLabel.textAlignment = NSTextAlignmentCenter;
  self.messageLabel.textColor = [NYPLConfiguration defaultBackgroundColor];
  self.messageLabel.text = NSLocalizedString(@"The download could not be completed.\nScroll down to 'View Issues' to see details.", nil);
  self.messageLabel.numberOfLines = 0;
  [self addSubview:self.messageLabel];
  [self.messageLabel autoPinEdgesToSuperviewEdges];
  
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

- (void)didChangePreferredContentSize
{
  self.messageLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
}

- (void)configureFailMessageWithProblemDocument:(NYPLProblemDocument *)problemDoc {
  if (problemDoc != nil) {
    self.messageLabel.text = NSLocalizedString(@"The download could not be completed.\nScroll down to 'View Issues' to see details.", nil);
  } else {
    self.messageLabel.text = NSLocalizedString(@"The download could not be completed.", nil);
  }
}

@end
