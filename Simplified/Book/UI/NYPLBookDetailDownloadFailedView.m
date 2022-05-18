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
  
  [self updateColors];
  
  self.showAudiobookError = NO;
  self.messageLabel = [[UILabel alloc] init];
  self.messageLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
  self.messageLabel.textAlignment = NSTextAlignmentCenter;
  self.messageLabel.textColor = [UIColor whiteColor];
  self.messageLabel.text = NSLocalizedString(@"The download could not be completed.", nil);
  self.messageLabel.numberOfLines = 0;
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

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
  [super traitCollectionDidChange:previousTraitCollection];
  
  if (@available(iOS 12.0, *)) {
    if (previousTraitCollection && UIScreen.mainScreen.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle) {
      [self updateColors];
    }
  }
}
- (void)setHidden:(BOOL)hidden {
  [super setHidden:hidden];
  /// The height of this view is constrainted to the normal view and downloading view.
  /// If this is presenting an error message which takes more than 1 line,
  /// we need to set the message to an empty string when this view is being hidden,
  /// so the other views can resize to the height they need.
  if (hidden) {
    self.messageLabel.text = @"";
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

- (void)didChangePreferredContentSize
{
  self.messageLabel.font = [UIFont customFontForTextStyle:UIFontTextStyleBody];
}

- (void)configureFailMessageWithProblemDocument:(NYPLProblemDocument *)problemDoc {
  if (self.showAudiobookError) {
    self.messageLabel.text = NSLocalizedString(@"Your download did not complete successfully. Retry or contact support.", nil);
    return;
  }
  
  if (problemDoc != nil) {
    self.messageLabel.text = NSLocalizedString(@"The download could not be completed.\nScroll down to 'View Issues' to see details.", nil);
  } else {
    self.messageLabel.text = NSLocalizedString(@"The download could not be completed.", nil);
  }
}

@end
