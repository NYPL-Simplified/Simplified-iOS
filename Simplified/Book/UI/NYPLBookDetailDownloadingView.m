@import PureLayout;
#import "SimplyE-Swift.h"

#import "NYPLMyBooksDownloadCenter.h"
#import "UIView+NYPLViewAdditions.h"
#import "NYPLLocalization.h"
#import "NYPLBookDetailDownloadingView.h"

@interface NYPLBookDetailDownloadingView ()

@property (nonatomic) UILabel *progressLabel;
@property (nonatomic) UILabel *percentageLabel;
@property (nonatomic) UIProgressView *progressView;

@end

@implementation NYPLBookDetailDownloadingView

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  CGFloat const sidePadding = 10;
  
  self.translatesAutoresizingMaskIntoConstraints = NO;
  
  self.progressLabel = [[UILabel alloc] init];
  self.progressLabel.font = [UIFont systemFontOfSize:14];
  self.progressLabel.text = NSLocalizedString(@"Requesting", nil);
  self.progressLabel.textColor = [UIColor whiteColor];
  [self addSubview:self.progressLabel];
  [self.progressLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
  [self.progressLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:sidePadding];
  
  self.percentageLabel = [[UILabel alloc] init];
  self.percentageLabel.font = [UIFont systemFontOfSize:14];
  self.percentageLabel.textColor = [UIColor whiteColor];
  self.percentageLabel.textAlignment = NSTextAlignmentRight;
  self.percentageLabel.text = NYPLLocalizationNotNeeded(@"0%");
  [self addSubview:self.percentageLabel];
  [self.percentageLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
  [self.percentageLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:sidePadding];
  
  self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
  self.progressView.backgroundColor = [NYPLConfiguration progressBarBackgroundColor];
  [self updateColors];
  [self addSubview:self.progressView];
  [self.progressView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
  [self.progressView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.progressLabel withOffset:sidePadding*2];
  [self.progressView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.percentageLabel withOffset:-sidePadding*2];
  
  return self;
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
  if (@available(iOS 12.0, *)) {
    if (UIScreen.mainScreen.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
      aColor = [NYPLConfiguration secondaryBackgroundColor];
    }
  }
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

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
  [super traitCollectionDidChange:previousTraitCollection];
  
  if (@available(iOS 12.0, *)) {
    if (previousTraitCollection && UIScreen.mainScreen.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle) {
      [self updateColors];
    }
  }
}

- (void)updateColors {
  if (@available(iOS 12.0, *)) {
    if (UIScreen.mainScreen.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
      self.progressView.tintColor = [NYPLConfiguration actionColor];
    }
  } else {
    self.progressView.tintColor = [NYPLConfiguration primaryBackgroundColor];
  }
}

#pragma mark -

- (double)downloadProgress
{
  return self.progressView.progress;
}

- (void)setDownloadProgress:(double const)downloadProgress
{
  self.progressView.progress = downloadProgress;
  
  self.percentageLabel.text = [NSString stringWithFormat:@"%d%%", (int) (downloadProgress * 100)];
}

- (void)setDownloadStarted:(BOOL)downloadStarted
{
  _downloadStarted = downloadStarted;
  NSString *status = downloadStarted ? @"Downloading" : @"Requesting";
  self.progressLabel.text = NSLocalizedString(status, nil);
  [self setNeedsLayout];
}

@end
