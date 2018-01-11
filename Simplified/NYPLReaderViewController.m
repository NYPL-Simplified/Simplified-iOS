@import Bugsnag;
@import WebKit;

#import "NYPLBook.h"
#import "NYPLBookRegistry.h"
#import "NYPLConfiguration.h"
#import "NYPLReaderReadiumView.h"
#import "NYPLReadiumViewSyncManager.h"
#import "NYPLReaderSettingsView.h"
#import "NYPLReaderTOCViewController.h"
#import "NYPLRoundedButton.h"
#import "UIFont+NYPLSystemFontOverride.h"
#import "NYPLReaderTOCElement.h"
#import "NYPLReaderSettings.h"
#import "UIView+NYPLViewAdditions.h"

#import "NYPLReaderViewController.h"
#import "SimplyE-Swift.h"
#import <PureLayout/PureLayout.h>

#define EDGE_OF_SCREEN_POINT_FRACTION    0.2

@interface NYPLReaderViewController ()
  <NYPLReaderSettingsViewDelegate, NYPLReaderTOCViewControllerDelegate, NYPLReaderRendererDelegate,
   UIPopoverControllerDelegate>

@property (nonatomic) UIPopoverController *activePopoverController;
@property (nonatomic) NSString *bookIdentifier;
@property (nonatomic) BOOL interfaceHidden, isAccessibilityConfigurationActive;
@property (nonatomic) NYPLReaderSettingsView *readerSettingsViewPhone;
@property (nonatomic) BOOL previousPageTurnWasRight;
@property (nonatomic) NYPLReaderReadiumView *rendererView;
@property (nonatomic) UIBarButtonItem *settingsBarButtonItem;
@property (nonatomic) UIBarButtonItem *bookmarkBarButtonItem;
@property (nonatomic) UIBarButtonItem *contentsBarButtonItem;
@property (nonatomic) NYPLReaderBookmark *currentBookmark;
@property (nonatomic) BOOL shouldHideInterfaceOnNextAppearance;
@property (nonatomic) UIView *bottomView;
@property (nonatomic) UIImageView *bottomViewImageView;
@property (nonatomic) UIView *bottomViewImageViewTopBorder;
@property (nonatomic) UIProgressView *bottomViewProgressView;
@property (nonatomic) UILabel *bottomViewProgressLabel;
@property (nonatomic) UIButton *largeTransparentAccessibilityButton;
@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic) int pagesProgressedSinceSave;

@property (nonatomic) UIView *footerView;
@property (nonatomic) UILabel *footerViewLabel;
@property (nonatomic) UIView *headerView;
@property (nonatomic) UILabel *headerViewLabel;

@property (nonatomic, getter = isStatusBarHidden) BOOL statusBarHidden;

@end

typedef NS_ENUM(NSInteger, NYPLReaderViewControllerDirection) {
  NYPLReaderViewControllerDirectionLeft,
  NYPLReaderViewControllerDirectionRight
};

@implementation NYPLReaderViewController

- (void)applyCurrentSettings
{
  self.navigationController.navigationBar.barTintColor =
    [NYPLReaderSettings sharedSettings].backgroundColor;
  
  switch([NYPLReaderSettings sharedSettings].colorScheme) {
    case NYPLReaderSettingsColorSchemeBlackOnSepia:
      self.activityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
      self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
      self.bottomViewImageView.backgroundColor = [NYPLConfiguration backgroundSepiaColor];
      self.bottomViewImageViewTopBorder.backgroundColor = [UIColor lightGrayColor];
      self.headerViewLabel.textColor = [UIColor darkGrayColor];
      self.footerViewLabel.textColor = [UIColor darkGrayColor];
      break;
    case NYPLReaderSettingsColorSchemeBlackOnWhite:
      self.activityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
      self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
      self.bottomViewImageView.backgroundColor = [NYPLConfiguration backgroundColor];
      self.bottomViewImageViewTopBorder.backgroundColor = [UIColor lightGrayColor];
      self.headerViewLabel.textColor = [UIColor darkGrayColor];
      self.footerViewLabel.textColor = [UIColor darkGrayColor];
      break;
    case NYPLReaderSettingsColorSchemeWhiteOnBlack:
      self.activityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
      self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
      self.bottomViewImageView.backgroundColor = [NYPLConfiguration backgroundDarkColor];
      self.bottomViewImageViewTopBorder.backgroundColor = [UIColor darkGrayColor];
      self.headerViewLabel.textColor = [UIColor colorWithWhite: 0.80 alpha:1];
      self.footerViewLabel.textColor = [UIColor colorWithWhite: 0.80 alpha:1];
      break;
  }
  
  self.activePopoverController.backgroundColor =
    [NYPLReaderSettings sharedSettings].backgroundColor;
}

- (instancetype)initWithBookIdentifier:(NSString *const)bookIdentifier
{
  self = [super init];
  if(!self) return nil;
  
  if(!bookIdentifier) {
    @throw NSInvalidArgumentException;
  }

  self.pagesProgressedSinceSave = 0;

  self.bookIdentifier = bookIdentifier;
  
  self.title = [[NYPLBookRegistry sharedRegistry] bookForIdentifier:self.bookIdentifier].title;
  
  self.hidesBottomBarWhenPushed = YES;
  
  [[NYPLBookRegistry sharedRegistry] delaySyncCommit];
  
  [[NYPLBookRegistry sharedRegistry]
   setState:NYPLBookStateUsed
   forIdentifier:self.bookIdentifier];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(voiceOverStatusChanged) name:UIAccessibilityVoiceOverStatusChanged object:nil];
  
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [[NYPLBookRegistry sharedRegistry] stopDelaySyncCommit];
}

#pragma mark NYPLReaderRendererDelegate

- (void)renderer:(__attribute__((unused)) id<NYPLReaderRenderer>)renderer
didEncounterCorruptionForBook:(__attribute__((unused)) NYPLBook *)book
{
  for(UIBarButtonItem *const item in self.navigationItem.rightBarButtonItems) {
    item.enabled = NO;
  }
  
  // Show the interface so the user can get back out.
  self.interfaceHidden = NO;
  
  [[[UIAlertView alloc]
    initWithTitle:NSLocalizedString(@"ReaderViewControllerCorruptTitle", nil)
    message:NSLocalizedString(@"ReaderViewControllerCorruptMessage", nil)
    delegate:nil
    cancelButtonTitle:nil
    otherButtonTitles:NSLocalizedString(@"OK", nil), nil]
   show];
}

- (void)rendererDidFinishLoading:(__attribute__((unused)) id<NYPLReaderRenderer>)renderer
{
  // Do nothing.
}

- (void)rendererDidBeginLongLoad:(__unused id<NYPLReaderRenderer>)render
{
  self.activityIndicatorView.hidden = NO;
  [self.activityIndicatorView startAnimating];
}

- (void)renderDidEndLongLoad:(__unused id<NYPLReaderRenderer>)render
{
  [self.activityIndicatorView stopAnimating];
  self.activityIndicatorView.hidden = YES;
}

- (void)renderer:(__unused id<NYPLReaderRenderer>)render didReceiveGesture:(NYPLReaderRendererGesture)gesture
{
  switch (gesture) {
  case NYPLReaderRendererGestureToggleUserInterface:
    [self setInterfaceHidden:!self.interfaceHidden animated:YES];
    break;
  }
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  
  [super viewDidLoad];
  
  self.automaticallyAdjustsScrollViewInsets = NO;
  
  self.shouldHideInterfaceOnNextAppearance = YES;
  
  [UINavigationBar setAnimationDuration:0.25];
  self.navigationController.navigationBar.translucent = YES;
  
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
  
  // Table of Contents button
  NYPLRoundedButton *const contentsButton = [NYPLRoundedButton button];
  contentsButton.bounds = CGRectMake(0, 0, 44.0f, 44.0f);
  contentsButton.layer.borderWidth = 0.0f;
  contentsButton.accessibilityLabel = [[NSString alloc] initWithFormat:NSLocalizedString(@"TOC", nil)];
  [contentsButton setImage:[UIImage imageNamed:@"TOC"] forState:UIControlStateNormal];
  [contentsButton addTarget:self
                action:@selector(didSelectContents)
      forControlEvents:UIControlEventTouchUpInside];
  
  self.contentsBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:contentsButton];
  
  // Settings button
  NYPLRoundedButton *const settingsButton = [NYPLRoundedButton button];
  settingsButton.bounds = CGRectMake(0, 0, 44.0f, 44.0f);
  settingsButton.layer.borderWidth = 0.0f;
  settingsButton.accessibilityLabel = NSLocalizedString(@"ReaderViewControllerToggleReaderSettings", nil);
  [settingsButton setImage:[UIImage imageNamed:@"Format"] forState:UIControlStateNormal];
  [settingsButton addTarget:self
                     action:@selector(didSelectSettings)
           forControlEvents:UIControlEventTouchUpInside];

  // Bookmark button
  NYPLRoundedButton *const bookmarkButton = [NYPLRoundedButton button];
  bookmarkButton.bounds = CGRectMake(0, 0, 44.0f, 44.0f);
  bookmarkButton.layer.borderWidth = 0.0f;
  bookmarkButton.accessibilityLabel = [[NSString alloc] initWithFormat:NSLocalizedString(@"Add Bookmark", nil)];
  [bookmarkButton setImage:[UIImage imageNamed:@"BookmarkOff"] forState:UIControlStateNormal];
  [bookmarkButton addTarget:self
                     action:@selector(toggleBookmark)
           forControlEvents:UIControlEventTouchUpInside];

  
  UIBarButtonItem *const TOCBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:contentsButton];
  self.settingsBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:settingsButton];
  self.bookmarkBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:bookmarkButton];

  // Bar button items require autolayout help 11.0+
  if (@available(iOS 11.0, *)) {
    [self.settingsBarButtonItem.customView autoSetDimensionsToSize:CGSizeMake(44,44)];
    [self.bookmarkBarButtonItem.customView autoSetDimensionsToSize:CGSizeMake(44,44)];
    [TOCBarButtonItem.customView autoSetDimensionsToSize:CGSizeMake(44,44)];
  }

  // Corruption may have occurred before we added these, so we need to set their enabled status
  // here (in addition to |readerView:didEncounterCorruptionForBook:|).
  self.navigationItem.rightBarButtonItems = @[self.bookmarkBarButtonItem, self.settingsBarButtonItem, self.contentsBarButtonItem];
  if(self.rendererView.bookIsCorrupt) {
    for(UIBarButtonItem *const item in self.navigationItem.rightBarButtonItems) {
      item.enabled = NO;
    }
  }
  
  self.rendererView = [[NYPLReaderReadiumView alloc]
                       initWithFrame:self.view.bounds
                       book:[[NYPLBookRegistry sharedRegistry]
                             bookForIdentifier:self.bookIdentifier]
                       delegate:self];
  self.rendererView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                        UIViewAutoresizingFlexibleHeight);
  [self.view addSubview:self.rendererView];
  
  // Add the giant transparent button to handle the "return to reading" action in VoiceOver
  self.largeTransparentAccessibilityButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [self.largeTransparentAccessibilityButton addTarget:self action:@selector(returnToReaderFocus) forControlEvents:UIControlEventTouchUpInside];
  self.largeTransparentAccessibilityButton.alpha = 0;
  self.largeTransparentAccessibilityButton.frame = CGRectMake(0, self.navigationController.navigationBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - self.navigationController.navigationBar.frame.size.height - self.bottomView.frame.size.height);
  self.largeTransparentAccessibilityButton.accessibilityLabel = NSLocalizedString(@"Return to Reader", @"Return to Reader");
  self.largeTransparentAccessibilityButton.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                                               UIViewAutoresizingFlexibleHeight);
  [self.view addSubview:self.largeTransparentAccessibilityButton];
  
  self.activityIndicatorView = [[UIActivityIndicatorView alloc]
                                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  [self.view addSubview:self.activityIndicatorView];
  [self.view bringSubviewToFront:self.activityIndicatorView];
  
  [self prepareBottomView];
  [self prepareHeaderFooterViews];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  [[NYPLBookRegistry sharedRegistry] save];
}

-(void)didMoveToParentViewController:(UIViewController *)parent {
  if (!parent && [self.rendererView bookHasMediaOverlaysBeingPlayed]) {
    [self.rendererView applyMediaOverlayPlaybackToggle];
  }
}

- (void) prepareHeaderFooterViews {
  self.headerView = [[UIView alloc] init];
  self.headerView.hidden = YES;
  
  self.headerViewLabel = [[UILabel alloc] init];
  self.headerViewLabel.numberOfLines = 2;
  self.headerViewLabel.textColor = [NYPLConfiguration mainColor];
  self.headerViewLabel.textAlignment = NSTextAlignmentCenter;
  [self.headerViewLabel setFont:[UIFont systemFontOfSize:13]];
  
  if (self.bookIdentifier) {
    NSString *title = [[NYPLBookRegistry sharedRegistry] bookForIdentifier:self.bookIdentifier].title;
    self.headerViewLabel.text = title;
  }
  
  [self.headerView addSubview:self.headerViewLabel];
  [self.view addSubview:self.headerView];

  if (@available (iOS 11.0, *)) {
    [self.headerView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor].active = YES;
    [self.headerView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.headerView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
  } else {
    [self.headerView autoPinEdgesToSuperviewMarginsExcludingEdge:ALEdgeBottom];
  }
  
  [self.headerView autoSetDimension:ALDimensionHeight toSize:60];
  
  [self.headerViewLabel autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.headerView withOffset:10];
  [self.headerViewLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
  [self.headerViewLabel autoSetDimension:ALDimensionWidth toSize:400 relation:NSLayoutRelationLessThanOrEqual];
  [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultHigh forConstraints:^{
    [self.headerViewLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.headerViewLabel autoPinEdgeToSuperviewEdge:ALEdgeRight];
  }];
  
  self.footerView = [[UIView alloc] init];
  self.footerView.hidden = YES;
  
  self.footerViewLabel = [[UILabel alloc] init];
  self.footerViewLabel.numberOfLines = 1;
  self.footerViewLabel.textColor = [NYPLConfiguration mainColor];
  self.footerViewLabel.textAlignment = NSTextAlignmentCenter;
  [self.footerViewLabel setFont:[UIFont systemFontOfSize:13]];
  
  [self.footerView addSubview:self.footerViewLabel];
  [self.view addSubview:self.footerView];
  
  if (@available (iOS 11.0, *)) {
    [self.footerView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor].active = YES;
    [self.footerView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.footerView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
  } else {
    [self.footerView autoPinEdgesToSuperviewMarginsExcludingEdge:ALEdgeTop];
  }
  
  [self.footerView autoSetDimension:ALDimensionHeight toSize:40];
  
  [self.footerViewLabel autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.footerView withOffset:-10];
  [self.footerViewLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:8];
  [self.footerViewLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:8];
}

- (void) prepareBottomView {
  self.bottomView = [[UIView alloc] init];
  self.bottomView.translatesAutoresizingMaskIntoConstraints = NO;
  self.bottomView.frame = CGRectMake(0, self.view.frame.size.height - 44, self.view.frame.size.width, 44);
  
  [self.view addSubview:self.bottomView];
  
  if (@available (iOS 11.0, *)) {
    
    [self.bottomView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor].active = YES;
    [self.bottomView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
    [self.bottomView autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
    [self.bottomView autoSetDimension:ALDimensionHeight toSize:44];
  
  } else {
  
    NSLayoutConstraint *constraintBV1 = [NSLayoutConstraint constraintWithItem:self.bottomView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem: self.view attribute:NSLayoutAttributeLeading multiplier:1.f constant:0];
    NSLayoutConstraint *constraintBV2 = [NSLayoutConstraint constraintWithItem:self.bottomView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem: self.view attribute:NSLayoutAttributeTrailing multiplier:1.f constant:0];
    NSLayoutConstraint *constraintBV3 = [NSLayoutConstraint constraintWithItem:self.bottomView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem: self.view attribute:NSLayoutAttributeBottom multiplier:1.f constant:-self.bottomView.frame.size.height];
    [self.view addConstraint:constraintBV1];
    [self.view addConstraint:constraintBV2];
    [self.view addConstraint:constraintBV3];
  }
  
  self.bottomViewImageView = [[UIImageView alloc] init];
  self.bottomViewImageView.translatesAutoresizingMaskIntoConstraints = NO;
  self.bottomViewImageView.backgroundColor = [NYPLConfiguration backgroundColor];
  self.bottomViewImageView.frame = self.bottomView.frame;
  
  CGSize mainViewSize = self.bottomViewImageView.bounds.size;
  CGFloat borderWidth = 0.5;
  UIColor *borderColor = [UIColor lightGrayColor];
  self.bottomViewImageViewTopBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, mainViewSize.width, borderWidth)];
  self.bottomViewImageViewTopBorder.opaque = YES;
  self.bottomViewImageViewTopBorder.backgroundColor = borderColor;
  self.bottomViewImageViewTopBorder.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
  [self.bottomViewImageView addSubview:self.bottomViewImageViewTopBorder];
  
  [self.bottomView addSubview:self.bottomViewImageView];
  NSLayoutConstraint *constraintAFL1 = [NSLayoutConstraint constraintWithItem:self.bottomViewImageView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem: self.bottomView attribute:NSLayoutAttributeLeading multiplier:1.f constant:0];
  NSLayoutConstraint *constraintAFL2 = [NSLayoutConstraint constraintWithItem:self.bottomViewImageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem: self.bottomView attribute:NSLayoutAttributeTop multiplier:1.f constant:0];
  NSLayoutConstraint *constraintAFL3 = [NSLayoutConstraint constraintWithItem:self.bottomViewImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem: self.bottomView attribute:NSLayoutAttributeHeight multiplier:1.f constant:self.bottomView.frame.size.height];
  NSLayoutConstraint *constraintAFL4 = [NSLayoutConstraint constraintWithItem:self.bottomViewImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem: self.bottomView attribute:NSLayoutAttributeWidth multiplier:1.f constant:self.bottomView.frame.size.width];
  [self.bottomView addConstraint:constraintAFL1];
  [self.bottomView addConstraint:constraintAFL2];
  [self.bottomView addConstraint:constraintAFL3];
  [self.bottomView addConstraint:constraintAFL4];
  
  self.bottomViewProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
  self.bottomViewProgressView.translatesAutoresizingMaskIntoConstraints = NO;
  self.bottomViewProgressView.frame = CGRectMake(0, 0, 0, 0);
  [self.bottomView addSubview:self.bottomViewProgressView];
  
  NSLayoutConstraint *constraintPV1 = [NSLayoutConstraint constraintWithItem:self.bottomViewProgressView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem: self.bottomView attribute:NSLayoutAttributeLeading multiplier:1.f constant:10];
  NSLayoutConstraint *constraintPV2 = [NSLayoutConstraint constraintWithItem:self.bottomViewProgressView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem: self.bottomView attribute:NSLayoutAttributeTop multiplier:1.f constant:self.bottomView.frame.size.height / 3];
  NSLayoutConstraint *constraintPV3 = [NSLayoutConstraint constraintWithItem:self.bottomViewProgressView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem: self.bottomView attribute:NSLayoutAttributeTrailing multiplier:1.f constant:-10];
  
  [self.bottomView addConstraint:constraintPV1];
  [self.bottomView addConstraint:constraintPV2];
  [self.bottomView addConstraint:constraintPV3];
  
  self.bottomViewProgressLabel = [[UILabel alloc] init];
  self.bottomViewProgressLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.bottomViewProgressLabel.backgroundColor = [UIColor clearColor];
  self.bottomViewProgressLabel.textColor = [NYPLConfiguration mainColor];
  [self.bottomViewProgressLabel setFont:[UIFont systemFontOfSize:13]];
  
  [self.bottomView addSubview:self.bottomViewProgressLabel];
  NSLayoutConstraint *constraintPL1 = [NSLayoutConstraint constraintWithItem:self.bottomViewProgressLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem: self.bottomViewProgressView attribute:NSLayoutAttributeTop multiplier:1.f constant:4];
  NSLayoutConstraint *constraintPL2 = [NSLayoutConstraint constraintWithItem:self.bottomViewProgressLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem: self.bottomViewProgressView attribute:NSLayoutAttributeCenterX multiplier:1.f constant:0];
  NSLayoutConstraint *constraintPL3 = [NSLayoutConstraint constraintWithItem:self.bottomViewProgressLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationGreaterThanOrEqual toItem: self.bottomViewProgressView attribute:NSLayoutAttributeLeading multiplier:1.f constant:10];
  NSLayoutConstraint *constraintPL4 = [NSLayoutConstraint constraintWithItem:self.bottomViewProgressLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationLessThanOrEqual toItem: self.bottomViewProgressView attribute:NSLayoutAttributeTrailing multiplier:1.f constant:-10];
  
  [self.bottomView addConstraint:constraintPL1];
  [self.bottomView addConstraint:constraintPL2];
  [self.bottomView addConstraint:constraintPL3];
  [self.bottomView addConstraint:constraintPL4];
}

- (BOOL)prefersStatusBarHidden
{
  return self.isStatusBarHidden;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
  return UIStatusBarAnimationSlide;
}

- (void)viewWillAppear:(BOOL)animated
{
  self.navigationItem.titleView = [[UIView alloc] init];

  [self applyCurrentSettings];
  
  [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
  if(self.shouldHideInterfaceOnNextAppearance) {
    self.shouldHideInterfaceOnNextAppearance = NO;
    self.interfaceHidden = YES;
  }
  
  self.isAccessibilityConfigurationActive = UIAccessibilityIsVoiceOverRunning();
  if (UIAccessibilityIsVoiceOverRunning()) {
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Magic Tap for Tools and Table of Contents", nil));
  }

  [super viewDidAppear:animated];
}

- (void)willMoveToParentViewController:(__attribute__((unused)) UIViewController *)parent
{
  self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
  self.navigationController.navigationBar.translucent = YES;
  self.navigationController.navigationBar.barTintColor = nil;
  if (!parent) {
    [[NYPLBookRegistry sharedRegistry] save];
  }
}

- (void)viewWillLayoutSubviews
{
  [self.activityIndicatorView centerInSuperview];
  [self.activityIndicatorView integralizeFrame];
}

#pragma mark Accessibility

- (void)setIsAccessibilityConfigurationActive:(BOOL)isAccessibilityConfigurationActive
{
  _isAccessibilityConfigurationActive = isAccessibilityConfigurationActive;
  self.largeTransparentAccessibilityButton.hidden = !isAccessibilityConfigurationActive;
}

- (void) voiceOverStatusChanged
{
  if (UIAccessibilityIsVoiceOverRunning())
    self.interfaceHidden = YES;
  self.isAccessibilityConfigurationActive = UIAccessibilityIsVoiceOverRunning();
}

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction
{
  if (direction == UIAccessibilityScrollDirectionLeft || direction == UIAccessibilityScrollDirectionRight) {
    if (direction == UIAccessibilityScrollDirectionLeft) {
      [self turnPageIsRight:YES];
    } else if (direction == UIAccessibilityScrollDirectionRight) {
      [self turnPageIsRight:NO];
    }
    return YES;
  }
  
  return NO;
}

- (BOOL)accessibilityPerformMagicTap
{
  self.interfaceHidden = !self.interfaceHidden;
  return YES;
}

- (BOOL)accessibilityPerformEscape
{
  if (self.activePopoverController.isPopoverVisible) {
    [self.activePopoverController dismissPopoverAnimated:YES];
  }
  [self.navigationController popViewControllerAnimated:YES];
  return YES;
}

#pragma mark NYPLReaderReadiumDelegate

- (void)
renderer:(__unused id<NYPLReaderRenderer>)renderer
didUpdateProgressWithinBook:(float)progressWithinBook
pageIndex:(NSUInteger const)pageIndex
pageCount:(NSUInteger const)pageCount
spineItemTitle:(NSString *const)title
{
  if (UIAccessibilityIsVoiceOverRunning()) {
    UIAccessibilityPostNotification(UIAccessibilityPageScrolledNotification,
                                    [NSString stringWithFormat:NSLocalizedString(@"Page %d of %d", nil),
                                     pageIndex + 1,
                                     pageCount]);
  }
  
  [self.bottomViewProgressView setProgress:progressWithinBook animated:NO];
  
  NSString *bookLocationString = [NSString stringWithFormat:@"Page %lu of %lu (%@)",
                                  pageIndex + 1,
                                  (unsigned long)pageCount,
                                  title ? title : NSLocalizedString(@"ReaderViewControllerCurrentChapter", nil)];
  
  self.bottomViewProgressLabel.text = bookLocationString;
  
  [UIView transitionWithView:self.footerViewLabel
                    duration:0.1
                     options:UIViewAnimationOptionTransitionCrossDissolve
                  animations:^{
                    self.footerViewLabel.text = bookLocationString;
                  } completion:nil];
  
  [self.bottomViewProgressLabel needsUpdateConstraints];
}

- (void)updateBookmarkIcon:(BOOL)on
{
  dispatch_async(dispatch_get_main_queue(), ^{
    NYPLRoundedButton *bookmarkButton = self.bookmarkBarButtonItem.customView;
    if (on) {
      [bookmarkButton setImage:[UIImage imageNamed:@"BookmarkOn"] forState:UIControlStateNormal];
      bookmarkButton.accessibilityLabel = [[NSString alloc] initWithFormat:NSLocalizedString(@"Remove Bookmark", nil)];
    } else {
      [bookmarkButton setImage:[UIImage imageNamed:@"BookmarkOff"] forState:UIControlStateNormal];
      bookmarkButton.accessibilityLabel = [[NSString alloc] initWithFormat:NSLocalizedString(@"Add Bookmark", nil)];
    }
  });
}
- (void)updateCurrentBookmark:(NYPLReaderBookmark *)bookmark
{
  self.currentBookmark = bookmark;
}

#pragma mark UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
  assert(popoverController == self.activePopoverController);
  
  if(UIAccessibilityIsVoiceOverRunning())
  {
    self.interfaceHidden = YES;
  }
  
  self.activePopoverController = nil;
}

#pragma mark UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(__attribute__((unused)) UIScrollView *)scrollView
{
  return nil;
}

#pragma mark NYPLReaderTOCViewControllerDelegate

- (void)TOCViewController:(__attribute__((unused)) NYPLReaderTOCViewController *)controller
  didSelectOpaqueLocation:(NYPLReaderRendererOpaqueLocation *const)opaqueLocation
{
  [self.rendererView openOpaqueLocation:opaqueLocation];
  
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad &&
     self.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassCompact) {
    [self.activePopoverController dismissPopoverAnimated:YES];
    if (!UIAccessibilityIsVoiceOverRunning())
      self.interfaceHidden = YES;
  } else {
    self.shouldHideInterfaceOnNextAppearance = YES;
    [self.navigationController popViewControllerAnimated:YES];
  }
}

- (void)TOCViewController:(__attribute__((unused))NYPLReaderTOCViewController *)controller
        didSelectBookmark:(NYPLReaderBookmark *)bookmark
{
  [self.rendererView gotoBookmark:bookmark];
  
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    [self.activePopoverController dismissPopoverAnimated:YES];
    if (!UIAccessibilityIsVoiceOverRunning())
      self.interfaceHidden = YES;
  } else {
    self.shouldHideInterfaceOnNextAppearance = YES;
    [self.navigationController popViewControllerAnimated:YES];
  }
}

- (void)TOCViewController:(__unused NYPLReaderTOCViewController *)controller
        didDeleteBookmark:(NYPLReaderBookmark *)bookmark
{
  [self.rendererView deleteBookmark:bookmark];
}

- (void)TOCViewController:(__unused NYPLReaderTOCViewController *)controller
didRequestSyncBookmarksWithCompletion:(void (^)(BOOL, NSArray<NYPLReaderBookmark *> *))completion
{
  [self.rendererView.syncManager syncBookmarksWithCompletion:completion];
}

#pragma mark NYPLReaderSettingsViewDelegate

- (void)readerSettingsView:(__attribute__((unused)) NYPLReaderSettingsView *)readerSettingsView
       didSelectBrightness:(CGFloat const)brightness
{
  [UIScreen mainScreen].brightness = brightness;
}

- (void)readerSettingsView:(__attribute__((unused)) NYPLReaderSettingsView *)readerSettingsView
      didSelectColorScheme:(NYPLReaderSettingsColorScheme const)colorScheme
{
  [NYPLReaderSettings sharedSettings].colorScheme = colorScheme;
  
  [self applyCurrentSettings];
}

- (void)readerSettingsView:(__attribute__((unused)) NYPLReaderSettingsView *)readerSettingsView
         didSelectFontSize:(NYPLReaderSettingsFontSize const)fontSize
{
  [NYPLReaderSettings sharedSettings].fontSize = fontSize;
  
  [self applyCurrentSettings];
}

- (void)readerSettingsView:(__attribute__((unused)) NYPLReaderSettingsView *)readerSettingsView
         didSelectFontFace:(NYPLReaderSettingsFontFace)fontFace
{
  [NYPLReaderSettings sharedSettings].fontFace = fontFace;
  
  [self applyCurrentSettings];
}

-(void)readerSettingsView:(__attribute__((unused)) NYPLReaderSettingsView *)readerSettingsView
      didSelectMediaOverlaysEnableClick:(NYPLReaderSettingsMediaOverlaysEnableClick) mediaOverlaysEnableClick {
  [NYPLReaderSettings sharedSettings].mediaOverlaysEnableClick = mediaOverlaysEnableClick;
  [self applyCurrentSettings];
}

-(void)readerSettingsViewDidSelectMediaOverlayToggle:(__attribute__((unused)) NYPLReaderSettingsView *)readerSettingsView {
  [[NYPLReaderSettings sharedSettings] toggleMediaOverlayPlayback];
}

#pragma mark -

- (void)setInterfaceHidden:(BOOL)interfaceHidden animated:(BOOL)animated
{
  if(self.rendererView.bookIsCorrupt && interfaceHidden) {
    // Hiding the UI would prevent the user from escaping from a corrupt book.
    return;
  }
  
  _interfaceHidden = interfaceHidden;
  
  if (interfaceHidden) {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    self.statusBarHidden = YES;
    [UIView animateWithDuration:0.25 animations:^{
      [self setNeedsStatusBarAppearanceUpdate];
    }];
  } else {
    self.statusBarHidden = NO;
    [self.navigationController setNavigationBarHidden:NO animated:animated];
  }
  
  if (animated) {
    [UIView transitionWithView:self.bottomView
                      duration:0.25
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                      self.bottomView.hidden = interfaceHidden;
                      self.footerView.hidden = !interfaceHidden;
                      self.headerView.hidden = !interfaceHidden;
                    } completion:nil];
  } else {
    self.bottomView.hidden = self.interfaceHidden;
    self.footerView.hidden = !self.interfaceHidden;
    self.headerView.hidden = !self.interfaceHidden;
  }
  
  if(self.interfaceHidden) {
    [self.readerSettingsViewPhone removeFromSuperview];
    self.readerSettingsViewPhone = nil;
  }
  
  // Accessibility
  self.rendererView.accessibilityElementsHidden = !interfaceHidden;
  id firstElement = interfaceHidden ? nil : self.navigationController.navigationBar;
  UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, firstElement);
  self.largeTransparentAccessibilityButton.userInteractionEnabled = UIAccessibilityIsVoiceOverRunning() && !interfaceHidden;
  self.largeTransparentAccessibilityButton.alpha = interfaceHidden ? 0.0 : 1.0;
  self.largeTransparentAccessibilityButton.isAccessibilityElement = !interfaceHidden;
  
  [self setNeedsStatusBarAppearanceUpdate];
}

- (void)setInterfaceHidden:(BOOL)interfaceHidden
{
  [self setInterfaceHidden:interfaceHidden animated:NO];
}

- (BOOL)returnToReaderFocus {
  self.interfaceHidden = YES;
  return YES;
}

- (void)didSelectSettings
{
  if(self.readerSettingsViewPhone) {
    [self.readerSettingsViewPhone removeFromSuperview];
    self.readerSettingsViewPhone = nil;
    return;
  }
  
  CGFloat const width =
    (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad &&
     self.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassCompact)
     ? 320
     : CGRectGetWidth(self.view.frame);
  
  NYPLReaderSettingsView *const readerSettingsView =
    [[NYPLReaderSettingsView alloc] initWithWidth:width];
  readerSettingsView.delegate = self;
  readerSettingsView.colorScheme = [NYPLReaderSettings sharedSettings].colorScheme;
  readerSettingsView.fontSize = [NYPLReaderSettings sharedSettings].fontSize;
  readerSettingsView.fontFace = [NYPLReaderSettings sharedSettings].fontFace;
  
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad &&
     self.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassCompact) {
    UIViewController *const viewController = [[UIViewController alloc] init];
    viewController.view = readerSettingsView;
    viewController.preferredContentSize = viewController.view.bounds.size;
    [self.activePopoverController dismissPopoverAnimated:NO];
    self.activePopoverController =
      [[UIPopoverController alloc] initWithContentViewController:viewController];
    self.activePopoverController.backgroundColor =
      [NYPLReaderSettings sharedSettings].backgroundColor;
    self.activePopoverController.delegate = self;
    [self.activePopoverController
     presentPopoverFromBarButtonItem:self.settingsBarButtonItem
     permittedArrowDirections:UIPopoverArrowDirectionUp
     animated:YES];
  } else {
    readerSettingsView.frame = CGRectOffset(readerSettingsView.frame,
                                            0,
                                            (CGRectGetHeight(self.view.frame) -
                                             CGRectGetHeight(readerSettingsView.frame)));
    [self.view addSubview:readerSettingsView];
    self.readerSettingsViewPhone = readerSettingsView;
    if (@available (iOS 11.0, *)) {
      [readerSettingsView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor].active = YES;
      [readerSettingsView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
      [readerSettingsView autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
      [readerSettingsView autoSetDimension:ALDimensionHeight toSize:readerSettingsView.frame.size.height];
    }
  }
  
  UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.readerSettingsViewPhone);
}

- (void)didSelectContents
{
  
  UIStoryboard *sb = [UIStoryboard storyboardWithName:@"NYPLReaderTOC" bundle:nil];
  NYPLReaderTOCViewController *viewController = [sb instantiateViewControllerWithIdentifier:@"NYPLReaderTOC"];
  viewController.delegate = self;
  viewController.tableOfContents = self.rendererView.TOCElements;
  viewController.bookTitle = [[NYPLBookRegistry sharedRegistry] bookForIdentifier:self.bookIdentifier].title;
  viewController.bookmarks = self.rendererView.bookmarkElements.mutableCopy;
  NYPLReaderReadiumView *rv = self.rendererView;
  viewController.currentChapter = [rv currentChapter];

  
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad &&
     self.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassCompact) {
    [self.activePopoverController dismissPopoverAnimated:NO];
    self.activePopoverController =
      [[UIPopoverController alloc] initWithContentViewController:viewController];
    self.activePopoverController.delegate = self;
    self.activePopoverController.backgroundColor =
      [NYPLReaderSettings sharedSettings].backgroundColor;
    [self.activePopoverController
     presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem
     permittedArrowDirections:UIPopoverArrowDirectionUp
     animated:YES];
  } else {
    [self.navigationController pushViewController:viewController animated:YES];
  }
}

- (void)toggleBookmark
{
  NYPLReaderReadiumView *rv = self.rendererView;
  if (self.currentBookmark) {
    [rv deleteBookmark:self.currentBookmark];
  }
  else {
    [rv addBookmark];
  }
}

- (void)turnPageIsRight:(BOOL)isRight
{
  NYPLReaderReadiumView *rv = self.rendererView;
  if (rv.isPageTurning) {
    return;
  } else {
    if (isRight) {
      [rv openPageRight];
    } else {
      [rv openPageLeft];
    }
    [self recordPageTurnForPeriodicSaving];
  }
}

// FIXME: This can be removed when we've solved the touch-gesture crashing.
// Until then, there is just too many users losing their page position to not necessitate
// something to be saving the position more frequently while still in the book.
-(void)recordPageTurnForPeriodicSaving
{
  self.pagesProgressedSinceSave++;
  if (self.pagesProgressedSinceSave > 6) {
    [[NYPLBookRegistry sharedRegistry] save];
    self.pagesProgressedSinceSave = 0;
  }
}

// FIXME: This can be removed when sufficient data has been collected
// Bug: Something has gone wrong with the VC array configuration. Observed in crash analytics.
- (void)reportPageViewControllerErrorToBugnsag
{
  [Bugsnag notifyError:[NSError errorWithDomain:@"org.nypl.labs.SimplyE" code:6 userInfo:nil]
                 block:^(BugsnagCrashReport * _Nonnull report) {
                   report.context = @"NYPLReaderViewController";
                   report.severity = BSGSeverityWarning;
                   report.errorMessage = @"UIPageViewController was attempting to set 0 view controllers.";
                 }];
}

@end
