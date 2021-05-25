@import WebKit;

#import "NYPLBook.h"
#import "NYPLBookRegistry.h"
#import "NYPLConfiguration.h"
#import "NYPLReaderReadiumView.h"
#import "NYPLReaderSettingsView.h"
#import "NYPLReaderTOCViewController.h"
#import "UIFont+NYPLSystemFontOverride.h"
#import "NYPLReaderTOCElement.h"
#import "NYPLReaderSettings.h"
#import "UIView+NYPLViewAdditions.h"
#import "NYPLReadiumViewSyncManager.h"

#import "NYPLReaderViewController.h"
#import "SimplyE-Swift.h"
#import <PureLayout/PureLayout.h>

#define EDGE_OF_SCREEN_POINT_FRACTION    0.2

@interface NYPLReaderViewController ()
  <NYPLUserSettingsReaderDelegate, NYPLReaderTOCViewControllerDelegate, NYPLReaderRendererDelegate, UIPopoverPresentationControllerDelegate>

@property (nonatomic) UIViewController *activePopoverController;
@property (nonatomic) NSString *bookIdentifier;
@property (nonatomic) BOOL interfaceHidden, isAccessibilityConfigurationActive;
@property (nonatomic) BOOL previousPageTurnWasRight;
@property (nonatomic) NYPLReaderReadiumView *rendererView;
@property (nonatomic) UIBarButtonItem *settingsBarButtonItem;
@property (nonatomic) UIBarButtonItem *bookmarkBarButtonItem;
@property (nonatomic) UIBarButtonItem *contentsBarButtonItem;
@property (nonatomic) NYPLReadiumBookmark *currentBookmark;
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
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(voiceOverStatusChanged)
                                               name:UIAccessibilityVoiceOverStatusChanged
                                             object:nil];
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
  self.interfaceHidden = NO;
  UIAlertController *alert = [NYPLAlertUtils
                              alertWithTitle:@"ReaderViewControllerCorruptTitle"
                              message:@"ReaderViewControllerCorruptMessage"];
  [self presentViewController:alert animated:YES completion:nil];
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
  
  self.contentsBarButtonItem = [[UIBarButtonItem alloc]
                                initWithImage:[UIImage imageNamed:@"TOC"]
                                style:UIBarButtonItemStylePlain
                                target:self
                                action:@selector(didSelectTOC)];
  self.contentsBarButtonItem.accessibilityLabel = NSLocalizedString(@"TOC", nil);

  self.settingsBarButtonItem = [[UIBarButtonItem alloc]
                                initWithImage:[UIImage imageNamed:@"Format"]
                                style:UIBarButtonItemStylePlain
                                target:self
                                action:@selector(didSelectSettings)];
  self.settingsBarButtonItem.accessibilityLabel =
  NSLocalizedString(@"ReaderViewControllerToggleReaderSettings", nil);

  // Bookmark button
  NYPLRoundedButton *const bookmarkButton = [[NYPLRoundedButton alloc] initWithType:NYPLRoundedButtonTypeNormal isFromDetailView:NO];
  bookmarkButton.bounds = CGRectMake(0, 0, 44.0f, 44.0f);
  bookmarkButton.layer.borderWidth = 0.0f;
  bookmarkButton.accessibilityLabel = [[NSString alloc] initWithFormat:NSLocalizedString(@"Add Bookmark", nil)];
  [bookmarkButton setImage:[UIImage imageNamed:@"BookmarkOff"] forState:UIControlStateNormal];
  [bookmarkButton addTarget:self
                     action:@selector(toggleBookmark)
           forControlEvents:UIControlEventTouchUpInside];
  self.bookmarkBarButtonItem = [[UIBarButtonItem alloc]
                                initWithCustomView:bookmarkButton];

  // Bar button items require autolayout help 11.0+
  if (@available(iOS 11.0, *)) {
    [self.bookmarkBarButtonItem.customView autoSetDimensionsToSize:CGSizeMake(44,44)];
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

- (void)prepareHeaderFooterViews {
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
  [super viewWillLayoutSubviews];
  [self.activityIndicatorView centerInSuperview];
}

- (void)willTransitionToTraitCollection:(__unused UITraitCollection *)newCollection
              withTransitionCoordinator:(__unused id<UIViewControllerTransitionCoordinator>)coordinator
{
  if (self.activePopoverController) {
    [self.activePopoverController.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    self.activePopoverController = nil;
  }
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];

  [self.activePopoverController.presentingViewController
   dismissViewControllerAnimated:NO completion:nil];
  self.activePopoverController = nil;
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
  if (self.activePopoverController.beingPresented) {
    [self.activePopoverController.presentingViewController dismissViewControllerAnimated:NO completion:nil];
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
                                    [NSString stringWithFormat:NSLocalizedString(@"Page %lu of %lu", nil),
                                     (unsigned long)pageIndex + 1,
                                     (unsigned long)pageCount]);
  }
  
  [self.bottomViewProgressView setProgress:progressWithinBook animated:NO];
  
  NSString *bookLocationString = [NSString stringWithFormat:@"Page %lu of %lu (%@)",
                                  (unsigned long)pageIndex + 1,
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
- (void)updateCurrentBookmark:(NYPLReadiumBookmark *)bookmark
{
  self.currentBookmark = bookmark;
}

#pragma mark UIPopoverPresentationControllerDelegate

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
  if (popoverPresentationController.presentedViewController == self.activePopoverController) {
    if(UIAccessibilityIsVoiceOverRunning()) {
      self.interfaceHidden = YES;
    }
    self.activePopoverController = nil;
  }
}

- (UIModalPresentationStyle)
adaptivePresentationStyleForPresentationController:(__attribute__((unused))  UIPresentationController *)controller
traitCollection:(__attribute__((unused)) UITraitCollection *)traitCollection
{
  // Prevent the popOver to be presented fullscreen on iPhones.
  return UIModalPresentationNone;
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
    [self.activePopoverController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    if (!UIAccessibilityIsVoiceOverRunning()) {
      self.interfaceHidden = YES;
    }
  } else {
    self.shouldHideInterfaceOnNextAppearance = YES;
    [self.navigationController popViewControllerAnimated:YES];
  }
}

- (void)TOCViewController:(__attribute__((unused))NYPLReaderTOCViewController *)controller
        didSelectBookmark:(NYPLReadiumBookmark *)bookmark
{
  [self.rendererView gotoBookmark:bookmark];
  
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    [self.activePopoverController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    if (!UIAccessibilityIsVoiceOverRunning()) {
      self.interfaceHidden = YES;
    }
  } else {
    self.shouldHideInterfaceOnNextAppearance = YES;
    [self.navigationController popViewControllerAnimated:YES];
  }
}

- (void)TOCViewController:(__unused NYPLReaderTOCViewController *)controller
        didDeleteBookmark:(NYPLReadiumBookmark *)bookmark
{
  [self.rendererView deleteBookmark:bookmark];
}

- (void)TOCViewController:(__unused NYPLReaderTOCViewController *)controller
didRequestSyncBookmarksWithCompletion:(void (^)(BOOL, NSArray<NYPLReadiumBookmark *> *))completion
{
  [self.rendererView.syncManager syncBookmarksWithCompletion:completion];
}

#pragma mark NYPLUserSettingsReaderDelegate

- (void)applyCurrentSettings
{
  self.navigationController.navigationBar.barTintColor =
  [NYPLReaderSettings sharedSettings].backgroundColor;

  self.activePopoverController.view.backgroundColor =
  [NYPLReaderSettings sharedSettings].backgroundColor;

  switch([NYPLReaderSettings sharedSettings].colorScheme) {
    case NYPLReaderSettingsColorSchemeBlackOnSepia:
      self.activityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
      self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
      self.bottomViewImageView.backgroundColor = [NYPLConfiguration readerBackgroundSepiaColor];
      self.bottomViewImageViewTopBorder.backgroundColor = [UIColor lightGrayColor];
      self.headerViewLabel.textColor = [UIColor darkGrayColor];
      self.footerViewLabel.textColor = [UIColor darkGrayColor];
      break;

    case NYPLReaderSettingsColorSchemeBlackOnWhite:
      self.activityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
      self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
      self.bottomViewImageView.backgroundColor = [NYPLConfiguration readerBackgroundColor];
      self.bottomViewImageViewTopBorder.backgroundColor = [UIColor lightGrayColor];
      self.headerViewLabel.textColor = [UIColor darkGrayColor];
      self.footerViewLabel.textColor = [UIColor darkGrayColor];
      break;

    case NYPLReaderSettingsColorSchemeWhiteOnBlack:
      self.activityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
      self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
      self.bottomViewImageView.backgroundColor = [NYPLConfiguration readerBackgroundDarkColor];
      self.bottomViewImageViewTopBorder.backgroundColor = [UIColor darkGrayColor];
      self.headerViewLabel.textColor = [UIColor colorWithWhite: 0.80 alpha:1];
      self.footerViewLabel.textColor = [UIColor colorWithWhite: 0.80 alpha:1];
      break;
  }
}

- (NYPLR1R2UserSettings *)userSettings
{
  return [[NYPLR1R2UserSettings alloc] init];
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
  if (self.activePopoverController && self.activePopoverController == self.presentedViewController) {
    [self dismissViewControllerAnimated:NO completion:nil];
  }

  NYPLUserSettingsVC *vc = [[NYPLUserSettingsVC alloc] initWithDelegate:self];
  self.activePopoverController = vc;
  vc.modalPresentationStyle = UIModalPresentationPopover;
  vc.popoverPresentationController.delegate = self;
  vc.popoverPresentationController.barButtonItem = self.settingsBarButtonItem;
  [self presentViewController:vc animated:YES completion:^{
    vc.popoverPresentationController.passthroughViews = nil;
  }];
  UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, vc);
}

- (void)didSelectTOC
{
  UIStoryboard *sb = [UIStoryboard storyboardWithName:@"NYPLReaderTOC" bundle:nil];
  NYPLReaderTOCViewController *tocVC = [sb instantiateViewControllerWithIdentifier:@"NYPLReaderTOC"];
  tocVC.delegate = self;
  tocVC.tableOfContents = self.rendererView.TOCElements;
  tocVC.bookTitle = [[NYPLBookRegistry sharedRegistry] bookForIdentifier:self.bookIdentifier].title;
  tocVC.bookmarks = self.rendererView.bookmarkElements.mutableCopy;
  tocVC.currentChapter = [self.rendererView currentChapter];
  
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad &&
     self.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassCompact) {
    if (self.activePopoverController && self.activePopoverController == self.presentedViewController) {
      [self dismissViewControllerAnimated:NO completion:nil];
    }
    tocVC.modalPresentationStyle = UIModalPresentationPopover;
    tocVC.popoverPresentationController.delegate = self;
    tocVC.popoverPresentationController.barButtonItem = self.contentsBarButtonItem;
    self.activePopoverController = tocVC;
    [self presentViewController:tocVC animated:YES completion:nil];
  } else {
    [self.navigationController pushViewController:tocVC animated:YES];
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

@end
