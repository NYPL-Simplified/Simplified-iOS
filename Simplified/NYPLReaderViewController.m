@import WebKit;

#import "NYPLBook.h"
#import "NYPLBookRegistry.h"
#import "NYPLConfiguration.h"
#import "NYPLReaderReadiumView.h"
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
   UIPopoverControllerDelegate, UIGestureRecognizerDelegate, UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (nonatomic) UIPopoverController *activePopoverController;
@property (nonatomic) NSString *bookIdentifier;
@property (nonatomic) BOOL interfaceHidden, isAccessibilityConfigurationActive;
@property (nonatomic) NYPLReaderSettingsView *readerSettingsViewPhone;
@property (nonatomic) UIPageViewController *pageViewController;
@property (nonatomic) NSArray<UIViewController *> *dummyViewControllers;
@property (nonatomic) UIImageView *renderedImageView;
@property (nonatomic) BOOL previousPageTurnWasRight;
@property (nonatomic) UIView<NYPLReaderRenderer> *rendererView;
@property (nonatomic) UIBarButtonItem *settingsBarButtonItem;
@property (nonatomic) BOOL shouldHideInterfaceOnNextAppearance;
@property (nonatomic) UIView *bottomView;
@property (nonatomic) UIImageView *bottomViewImageView;
@property (nonatomic) UIView *bottomViewImageViewTopBorder;
@property (nonatomic) UIProgressView *bottomViewProgressView;
@property (nonatomic) UILabel *bottomViewProgressLabel;
@property (nonatomic) UIButton *largeTransparentAccessibilityButton;
@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;

@property (nonatomic) UIView *footerView;
@property (nonatomic) UILabel *footerViewLabel;
@property (nonatomic) UIView *headerView;
@property (nonatomic) UILabel *headerViewLabel;

@property (nonatomic, getter = isStatusBarHidden) BOOL statusBarHidden;

@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizer, *doubleTapGestureRecognizer;
@end

@implementation NYPLReaderViewController

- (void)applyCurrentSettings
{
  if ([self.renderedImageView superview])
    [self.renderedImageView removeFromSuperview];
  
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
  
  self.bookIdentifier = bookIdentifier;
  
  self.title = [[NYPLBookRegistry sharedRegistry] bookForIdentifier:self.bookIdentifier].title;
  
  self.hidesBottomBarWhenPushed = YES;
  
  [[NYPLBookRegistry sharedRegistry] delaySyncCommit];
  
  [[NYPLBookRegistry sharedRegistry]
   setState:NYPLBookStateUsed
   forIdentifier:self.bookIdentifier];
  
  self.tapGestureRecognizer = [[UITapGestureRecognizer alloc]
                               initWithTarget:self
                               action:@selector(didReceiveSingleTap:)];
  self.tapGestureRecognizer.cancelsTouchesInView = NO;
  self.tapGestureRecognizer.delegate = self;
  self.tapGestureRecognizer.numberOfTapsRequired = 1;
  
  [self.view addGestureRecognizer:self.tapGestureRecognizer];
  
  self.doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc]
                               initWithTarget:self
                               action:@selector(didReceiveDoubleTap:)];
  self.doubleTapGestureRecognizer.cancelsTouchesInView = NO;
  self.doubleTapGestureRecognizer.delegate = self;
  self.doubleTapGestureRecognizer.numberOfTapsRequired = 2;
  [self.view addGestureRecognizer:self.doubleTapGestureRecognizer];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(voiceOverStatusChanged) name:UIAccessibilityVoiceOverStatusChanged object:nil];
  
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [[NYPLBookRegistry sharedRegistry] stopDelaySyncCommit];
}

- (void)didReceiveSingleTap:(UIGestureRecognizer *const)gestureRecognizer {
  CGPoint p = [gestureRecognizer locationInView:self.view];
  CGFloat edgeOfScreenWidth = CGRectGetWidth(self.view.bounds) * EDGE_OF_SCREEN_POINT_FRACTION;
  if ([self.renderedImageView superview])
    [self.renderedImageView removeFromSuperview];
  
  NYPLReaderReadiumView *rv = [NYPLReaderSettings sharedSettings].currentReaderReadiumView;
  if (p.x < edgeOfScreenWidth) {
    if (rv.isPageTurning || !rv.canGoLeft)
      return;
    [self turnPageIsRight:NO];
  } else if (p.x > (CGRectGetWidth(self.view.bounds) - edgeOfScreenWidth)) {
    if (rv.isPageTurning || !rv.canGoRight)
      return;
    [self turnPageIsRight:YES];
  } else {
    [self setInterfaceHidden:!self.interfaceHidden animated:YES];
  }
}

- (void)didReceiveDoubleTap:(__unused UIGestureRecognizer *const)gestureRecognizer
{
  // No-op, for now, until we implement something like highlight
}

- (BOOL)gestureRecognizer:(__unused UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(__unused UIGestureRecognizer *)otherGestureRecognizer {
  return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
  CGPoint p = [touch locationInView:self.view];
  if (!self.interfaceHidden && CGRectContainsPoint(self.bottomView.frame, p))
    return NO;
  if (!self.interfaceHidden && self.readerSettingsViewPhone && CGRectContainsPoint(self.readerSettingsViewPhone.frame, p))
    return NO;
  CGFloat edgeOfScreenWidth = CGRectGetWidth(self.view.bounds) * EDGE_OF_SCREEN_POINT_FRACTION;
  if (gestureRecognizer == self.tapGestureRecognizer) {
    if (p.x < edgeOfScreenWidth || p.x > (CGRectGetWidth(self.view.bounds) - edgeOfScreenWidth))
      return YES;
    return ![[NYPLReaderSettings sharedSettings].currentReaderReadiumView touchIntersectsLink:touch];
  } else if (gestureRecognizer == self.doubleTapGestureRecognizer) {
    return !(p.x < edgeOfScreenWidth || p.x > (CGRectGetWidth(self.view.bounds) - edgeOfScreenWidth));
  }
  return YES;
}

- (BOOL)gestureRecognizer:(__unused UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(__unused UIGestureRecognizer *)otherGestureRecognizer {
  return NO;
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

#pragma mark UIViewController

- (void)viewDidLoad
{
  
  [super viewDidLoad];
  
  self.automaticallyAdjustsScrollViewInsets = NO;
  
  self.shouldHideInterfaceOnNextAppearance = YES;
  
  [UINavigationBar setAnimationDuration:0.25];
  self.navigationController.navigationBar.translucent = YES;
  
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
  
  NYPLRoundedButton *const settingsButton = [NYPLRoundedButton button];
  settingsButton.accessibilityLabel = NSLocalizedString(@"ReaderViewControllerToggleReaderSettings", nil);
  [settingsButton setTitle:@"Aa" forState:UIControlStateNormal];
  [settingsButton sizeToFit];
  // We set a larger font after sizing because we want large text in a standard-size button.
  settingsButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
  [settingsButton addTarget:self
                     action:@selector(didSelectSettings)
           forControlEvents:UIControlEventTouchUpInside];
  self.settingsBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:settingsButton];
  
  NYPLRoundedButton *const TOCButton = [NYPLRoundedButton button];
  TOCButton.accessibilityLabel = [[NSString alloc] initWithFormat:NSLocalizedString(@"TOC", nil)];
  TOCButton.bounds = settingsButton.bounds;
  [TOCButton setImage:[UIImage imageNamed:@"TOC"] forState:UIControlStateNormal];
  [TOCButton addTarget:self
                action:@selector(didSelectTOC)
      forControlEvents:UIControlEventTouchUpInside];
  
  UIBarButtonItem *const TOCBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:TOCButton];
  
  // Corruption may have occurred before we added these, so we need to set their enabled status
  // here (in addition to |readerView:didEncounterCorruptionForBook:|).
  self.navigationItem.rightBarButtonItems = @[TOCBarButtonItem, self.settingsBarButtonItem];
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
  
  // ----------- page view
  self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
  self.pageViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.pageViewController.dataSource = self;
  self.pageViewController.delegate = self;
  [[self.pageViewController view] setFrame:[[self view] bounds]];
  for (UIGestureRecognizer *gr in self.pageViewController.gestureRecognizers) {
    if ([gr isKindOfClass:[UITapGestureRecognizer class]])
      gr.enabled = NO;
  }
  
  self.dummyViewControllers = @[[[UIViewController alloc] init], [[UIViewController alloc] init], [[UIViewController alloc] init]];
  for (UIViewController *v in self.dummyViewControllers)
    [v.view setBackgroundColor:[UIColor whiteColor]];
  [self.dummyViewControllers.firstObject.view addSubview:self.rendererView];
  self.renderedImageView = [[UIImageView alloc] init];
  
  NSArray *viewControllers = [NSArray arrayWithObject:self.dummyViewControllers.firstObject];
  
  [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
  
  [self addChildViewController:self.pageViewController];
  [[self view] addSubview:[self.pageViewController view]];
  [self.pageViewController didMoveToParentViewController:self];
  // ----------- page view
  
  // Add the giant transparent button to handle the "return to reading" action in VoiceOver
  self.largeTransparentAccessibilityButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [self.largeTransparentAccessibilityButton addTarget:self action:@selector(returnToReaderFocus) forControlEvents:UIControlEventTouchUpInside];
  self.largeTransparentAccessibilityButton.alpha = 0;
  self.largeTransparentAccessibilityButton.frame = CGRectMake(0, self.navigationController.navigationBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - self.navigationController.navigationBar.frame.size.height - self.bottomView.frame.size.height);
  [self.view addSubview:self.largeTransparentAccessibilityButton];
  self.largeTransparentAccessibilityButton.userInteractionEnabled = NO;
  self.largeTransparentAccessibilityButton.accessibilityLabel = NSLocalizedString(@"Return to Reader", @"Return to Reader");
  self.largeTransparentAccessibilityButton.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                                               UIViewAutoresizingFlexibleHeight);
  
  self.activityIndicatorView = [[UIActivityIndicatorView alloc]
                                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  [self.view addSubview:self.activityIndicatorView];
  [self.view bringSubviewToFront:self.activityIndicatorView];
  
  [self prepareBottomView];
  [self prepareHeaderFooterViews];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncLastRead) name:UIApplicationWillEnterForegroundNotification object:nil];
  
}

-(void)didMoveToParentViewController:(UIViewController *)parent {
  if (!parent && [[NYPLReaderSettings sharedSettings].currentReaderReadiumView bookHasMediaOverlaysBeingPlayed]) {
    [[NYPLReaderSettings sharedSettings].currentReaderReadiumView applyMediaOverlayPlaybackToggle];
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

  [self.headerView autoPinEdgesToSuperviewMarginsExcludingEdge:ALEdgeBottom];
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
  
  [self.footerView autoPinEdgesToSuperviewMarginsExcludingEdge:ALEdgeTop];
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
  NSLayoutConstraint *constraintBV1 = [NSLayoutConstraint constraintWithItem:self.bottomView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem: self.view attribute:NSLayoutAttributeLeading multiplier:1.f constant:0];
  NSLayoutConstraint *constraintBV2 = [NSLayoutConstraint constraintWithItem:self.bottomView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem: self.view attribute:NSLayoutAttributeTrailing multiplier:1.f constant:0];
  NSLayoutConstraint *constraintBV3 = [NSLayoutConstraint constraintWithItem:self.bottomView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem: self.view attribute:NSLayoutAttributeBottom multiplier:1.f constant:-self.bottomView.frame.size.height];
  [self.view addConstraint:constraintBV1];
  [self.view addConstraint:constraintBV2];
  [self.view addConstraint:constraintBV3];
  
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

- (void)syncLastRead
{
  [[NYPLReaderSettings sharedSettings].currentReaderReadiumView syncLastReadingPosition];
}

- (void)viewDidAppear:(BOOL)animated
{
  if(self.shouldHideInterfaceOnNextAppearance) {
    self.shouldHideInterfaceOnNextAppearance = NO;
    self.interfaceHidden = YES;
    self.tapGestureRecognizer.enabled = !UIAccessibilityIsVoiceOverRunning();
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
}

- (void)viewWillLayoutSubviews
{
  [self.activityIndicatorView centerInSuperview];
  [self.activityIndicatorView integralizeFrame];
}

#pragma mark Accessibility

- (void)setIsAccessibilityConfigurationActive:(BOOL)isAccessibilityConfigurationActive
{
  if (_isAccessibilityConfigurationActive != isAccessibilityConfigurationActive) {
    _isAccessibilityConfigurationActive = isAccessibilityConfigurationActive;
    self.largeTransparentAccessibilityButton.userInteractionEnabled = (_isAccessibilityConfigurationActive && !self.interfaceHidden);
    self.tapGestureRecognizer.enabled = !_isAccessibilityConfigurationActive;
    
    if (_isAccessibilityConfigurationActive) {
      
      if ([self.rendererView superview])
        [self.rendererView removeFromSuperview];
      [self.view insertSubview:self.rendererView belowSubview:self.largeTransparentAccessibilityButton];
      
      [self.pageViewController willMoveToParentViewController:nil];
      [self.pageViewController.view removeFromSuperview];
      [self.pageViewController removeFromParentViewController];
      [self.pageViewController didMoveToParentViewController:nil];
      
    } else {
      
      if ([self.rendererView superview])
        [self.rendererView removeFromSuperview];
      
      [self.pageViewController willMoveToParentViewController:self];
      [self addChildViewController:self.pageViewController];
      [self.view insertSubview:self.pageViewController.view belowSubview:self.largeTransparentAccessibilityButton];
      [self.pageViewController didMoveToParentViewController:self];
      [self.pageViewController.viewControllers[0].view addSubview:self.rendererView];
      
    }
  }
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
                    duration:0.2
                     options:UIViewAnimationOptionTransitionCrossDissolve
                  animations:^{
                    self.footerViewLabel.text = bookLocationString;
                  } completion:nil];
  
  [self.bottomViewProgressLabel needsUpdateConstraints];
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

#pragma mark UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(__unused UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
  NYPLReaderReadiumView *rv = [NYPLReaderSettings sharedSettings].currentReaderReadiumView;
  if (rv.isPageTurning || ![rv canGoLeft])
    return nil;
  NSInteger i = [self.dummyViewControllers indexOfObject:viewController];
  i = (i+2)%3;
  return [self.dummyViewControllers objectAtIndex:i];
}

- (UIViewController *)pageViewController:(__unused UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
  NYPLReaderReadiumView *rv = [NYPLReaderSettings sharedSettings].currentReaderReadiumView;
  if (rv.isPageTurning || ![rv canGoRight])
    return nil;
  NSInteger i = [self.dummyViewControllers indexOfObject:viewController];
  i = (i+1)%3;
  return [self.dummyViewControllers objectAtIndex:i];
}

#pragma mark UIPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray<UIViewController *> *)pendingViewControllers
{
  self.view.userInteractionEnabled = NO;
  
  // Don't bother with any of this offscreen rendering nonsense if VO is active
  if (UIAccessibilityIsVoiceOverRunning())
    return;
  
  UIViewController *pvc = pageViewController.viewControllers.firstObject;
  UIViewController *nvc = pendingViewControllers.firstObject;
  NSInteger pi = [self.dummyViewControllers indexOfObject:pvc];
  NSInteger ni = [self.dummyViewControllers indexOfObject:nvc];
  BOOL turnRight = ((pi+1)%3)==ni;
  self.previousPageTurnWasRight = turnRight;
  
  UIGraphicsBeginImageContextWithOptions(self.rendererView.bounds.size, YES, 0.0f);
  [pvc.view drawViewHierarchyInRect:self.rendererView.bounds afterScreenUpdates:NO];
  UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  if ([self.renderedImageView superview])
    [self.renderedImageView removeFromSuperview];
  
  [self.rendererView removeFromSuperview];
  [[pendingViewControllers.firstObject view] addSubview:self.rendererView];
  self.rendererView.frame = pendingViewControllers.firstObject.view.bounds;
  
  [self turnPageIsRight:turnRight];
  
  // Hack to work around an issue that would occasionally occur after an orientation change.
  ((WKWebView *) self.rendererView.subviews[0]).scrollView.contentSize = self.rendererView.bounds.size;
  
  self.renderedImageView.image = snapshotImage;
  self.renderedImageView.frame = CGRectMake(0, 0, snapshotImage.size.width, snapshotImage.size.height);
  [pvc.view addSubview:self.renderedImageView];
}

- (void)pageViewController:(__unused UIPageViewController *)pageViewController didFinishAnimating:(__unused BOOL)finished previousViewControllers:(__unused NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed
{
  self.view.userInteractionEnabled = YES;
  
  if (completed) {
    if ([self.renderedImageView superview])
      [self.renderedImageView removeFromSuperview];
  } else {
    [self turnPageIsRight:!self.previousPageTurnWasRight];
    [[NYPLReaderSettings sharedSettings].currentReaderReadiumView removeFromSuperview];
    [pageViewController.viewControllers.firstObject.view insertSubview:[NYPLReaderSettings sharedSettings].currentReaderReadiumView belowSubview:self.renderedImageView];
  }
}

#pragma mark NYPLReaderTOCViewControllerDelegate

- (void)TOCViewController:(__attribute__((unused)) NYPLReaderTOCViewController *)controller
didSelectOpaqueLocation:(NYPLReaderRendererOpaqueLocation *const)opaqueLocation
{
  [self.rendererView openOpaqueLocation:opaqueLocation];
  
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    [self.activePopoverController dismissPopoverAnimated:YES];
    if (!UIAccessibilityIsVoiceOverRunning())
      self.interfaceHidden = YES;
  } else {
    self.shouldHideInterfaceOnNextAppearance = YES;
    [self.navigationController popViewControllerAnimated:YES];
  }
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
  
  self.navigationController.interactivePopGestureRecognizer.enabled = !interfaceHidden;
  
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
    (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad
     ? 320
     : CGRectGetWidth(self.view.frame));
  
  NYPLReaderSettingsView *const readerSettingsView =
    [[NYPLReaderSettingsView alloc] initWithWidth:width];
  readerSettingsView.delegate = self;
  readerSettingsView.colorScheme = [NYPLReaderSettings sharedSettings].colorScheme;
  readerSettingsView.fontSize = [NYPLReaderSettings sharedSettings].fontSize;
  readerSettingsView.fontFace = [NYPLReaderSettings sharedSettings].fontFace;
  
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
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
  }
  
  UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.readerSettingsViewPhone);
}

- (void)didSelectTOC
{
  NYPLReaderTOCViewController *const viewController =
    [[NYPLReaderTOCViewController alloc] initWithTOCElements:self.rendererView.TOCElements];
  
  viewController.delegate = self;
  
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
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

- (void)turnPageIsRight:(BOOL)isRight
{
  NYPLReaderReadiumView *rv = [[NYPLReaderSettings sharedSettings] currentReaderReadiumView];
  if (rv.isPageTurning) {
    return;
  } else {
    if (isRight)
      [rv openPageRight];
    else
      [rv openPageLeft];
  }
}

- (void)touchesBegan:(__unused NSSet<UITouch *> *)touches withEvent:(__unused UIEvent *)event
{
  if (self.renderedImageView.superview != nil && (self.renderedImageView.superview == self.rendererView.superview)) {
    [self.renderedImageView removeFromSuperview];
  }
}

@end
