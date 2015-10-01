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

#import "NYPLReaderViewController.h"

#define EDGE_OF_SCREEN_POINT_FRACTION    0.1

@interface NYPLReaderViewController ()
  <NYPLReaderSettingsViewDelegate, NYPLReaderTOCViewControllerDelegate, NYPLReaderRendererDelegate,
   UIPopoverControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic) UIPopoverController *activePopoverController;
@property (nonatomic) NSString *bookIdentifier;
@property (nonatomic) BOOL interfaceHidden;
@property (nonatomic) NYPLReaderSettingsView *readerSettingsViewPhone;
@property (nonatomic) UIView<NYPLReaderRenderer> *rendererView;
@property (nonatomic) UIBarButtonItem *settingsBarButtonItem;
@property (nonatomic) BOOL shouldHideInterfaceOnNextAppearance;
@property (nonatomic) UIView *bottomView;
@property (nonatomic) UIImageView *bottomViewImageView;
@property (nonatomic) UIView *bottomViewImageViewTopBorder;
@property (nonatomic) UIProgressView *bottomViewProgressView;
@property (nonatomic) UILabel *bottomViewProgressLabel;
@property (nonatomic) UIButton *largeTransparentAccessibilityButton;

@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic) UISwipeGestureRecognizer *leftSwipeGestureRecognizer, *rightSwipeGestureRecognizer;
@end

@implementation NYPLReaderViewController

- (void)applyCurrentSettings
{
  self.navigationController.navigationBar.barTintColor =
    [NYPLReaderSettings sharedSettings].backgroundColor;
  
  switch([NYPLReaderSettings sharedSettings].colorScheme) {
    case NYPLReaderSettingsColorSchemeBlackOnSepia:
      self.bottomViewImageView.backgroundColor = [NYPLConfiguration backgroundSepiaColor];
      self.bottomViewImageViewTopBorder.backgroundColor = [UIColor lightGrayColor];
      break;
    case NYPLReaderSettingsColorSchemeBlackOnWhite:
      self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
      self.bottomViewImageView.backgroundColor = [NYPLConfiguration backgroundColor];
      self.bottomViewImageViewTopBorder.backgroundColor = [UIColor lightGrayColor];
      break;
    case NYPLReaderSettingsColorSchemeWhiteOnBlack:
      self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
      self.bottomViewImageView.backgroundColor = [NYPLConfiguration backgroundDarkColor];
      self.bottomViewImageViewTopBorder.backgroundColor = [UIColor darkGrayColor];
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
                               action:@selector(didReceiveGesture:)];
  self.tapGestureRecognizer.cancelsTouchesInView = NO;
  self.tapGestureRecognizer.delegate = self;
  self.tapGestureRecognizer.numberOfTapsRequired = 1;
  [self.view addGestureRecognizer:self.tapGestureRecognizer];
  
  self.leftSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc]
                                     initWithTarget:self
                                     action:@selector(didReceiveSwipeGesture:)];
  self.leftSwipeGestureRecognizer.cancelsTouchesInView = NO;
  self.leftSwipeGestureRecognizer.delegate = self;
  self.leftSwipeGestureRecognizer.numberOfTouchesRequired = 1;
  self.leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
  [self.view addGestureRecognizer:self.leftSwipeGestureRecognizer];
  
  self.rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc]
                                     initWithTarget:self
                                     action:@selector(didReceiveSwipeGesture:)];
  self.rightSwipeGestureRecognizer.cancelsTouchesInView = NO;
  self.rightSwipeGestureRecognizer.delegate = self;
  self.rightSwipeGestureRecognizer.numberOfTouchesRequired = 1;
  self.rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
  [self.view addGestureRecognizer:self.rightSwipeGestureRecognizer];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(voiceOverStatusChanged) name:UIAccessibilityVoiceOverStatusChanged object:nil];
  
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [[NYPLBookRegistry sharedRegistry] stopDelaySyncCommit];
}

- (void)didReceiveGesture:(UIGestureRecognizer *const)gestureRecognizer {
  CGPoint p = [gestureRecognizer locationInView:self.view];
  CGFloat edgeOfScreenWidth = CGRectGetWidth(self.view.bounds) * EDGE_OF_SCREEN_POINT_FRACTION;
  if (p.x < edgeOfScreenWidth) {
    [[NYPLReaderSettings sharedSettings].currentReaderReadiumView openPageLeft];
  } else if (p.x > (CGRectGetWidth(self.view.bounds) - edgeOfScreenWidth)) {
    [[NYPLReaderSettings sharedSettings].currentReaderReadiumView openPageLeft];
  } else {
    self.interfaceHidden = !self.interfaceHidden;
  }
}

- (void)didReceiveSwipeGesture:(UISwipeGestureRecognizer *const)gestureRecognizer {
  if (gestureRecognizer.direction == UISwipeGestureRecognizerDirectionLeft)
    [[NYPLReaderSettings sharedSettings].currentReaderReadiumView openPageRight];
  else if (gestureRecognizer.direction == UISwipeGestureRecognizerDirectionRight)
    [[NYPLReaderSettings sharedSettings].currentReaderReadiumView openPageLeft];
}

- (BOOL)gestureRecognizer:(__attribute__((unused)) UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(__attribute__((unused)) UIGestureRecognizer *)otherGestureRecognizer {
  return YES;
}

- (BOOL)gestureRecognizer:(__attribute__((unused)) UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(__attribute__((unused))UITouch *)touch {
  return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
  if (gestureRecognizer == self.tapGestureRecognizer) {
    if (otherGestureRecognizer == self.leftSwipeGestureRecognizer || otherGestureRecognizer == self.rightSwipeGestureRecognizer)
      return YES;
  }
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

#pragma mark UIViewController

- (void)viewDidLoad
{
  
  [super viewDidLoad];
  
  self.automaticallyAdjustsScrollViewInsets = NO;
  
  self.shouldHideInterfaceOnNextAppearance = YES;
  
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
  
  NYPLRoundedButton *const settingsButton = [NYPLRoundedButton button];
  settingsButton.accessibilityLabel = [[NSString alloc] initWithFormat:NSLocalizedString(@"ReaderSettings", nil)];
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
  
  [self.view addSubview:self.rendererView];
  
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
  
  [self prepareBottomView];
}

-(void)didMoveToParentViewController:(UIViewController *)parent {
  if (!parent && [[NYPLReaderSettings sharedSettings].currentReaderReadiumView bookHasMediaOverlaysBeingPlayed]) {
    [[NYPLReaderSettings sharedSettings].currentReaderReadiumView applyMediaOverlayPlaybackToggle];
  }
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

-(void)didUpdateProgressSpineItemPercentage:(NSNumber *)spineItemPercentage bookPercentage:(NSNumber *)bookPercentage withCurrentSpineItemDetails: (NSDictionary *) currentSpineItemDetails{
  [self.bottomViewProgressView setProgress:bookPercentage.floatValue / 100 animated:YES];  
  NSString *title = [currentSpineItemDetails objectForKey:@"tocElementTitle"];
  
  NSString *bookLocalized = NSLocalizedString(@"Book", nil);
  NSString *leftInLozalized = NSLocalizedString(@"leftin", nil);
  
  self.bottomViewProgressLabel.text = [NSString stringWithFormat:@"%@ %@%% (%@%% %@ %@)", bookLocalized, bookPercentage.stringValue, spineItemPercentage.stringValue, leftInLozalized, title];
  [self.bottomViewProgressLabel needsUpdateConstraints];
}

- (BOOL)prefersStatusBarHidden
{
  return self.interfaceHidden;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
  return UIStatusBarAnimationNone;
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
    self.interfaceHidden = UIAccessibilityIsVoiceOverRunning();
    self.tapGestureRecognizer.enabled = !UIAccessibilityIsVoiceOverRunning();
  }

  [super viewDidAppear:animated];
}

- (void)willMoveToParentViewController:(__attribute__((unused)) UIViewController *)parent
{
  self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
  self.navigationController.navigationBar.barTintColor = nil;
}

#pragma mark Accessibility

- (void) voiceOverStatusChanged
{
  if (UIAccessibilityIsVoiceOverRunning())
    self.interfaceHidden = YES;
  self.tapGestureRecognizer.enabled = !UIAccessibilityIsVoiceOverRunning();
  self.largeTransparentAccessibilityButton.userInteractionEnabled = (UIAccessibilityIsVoiceOverRunning() && !self.interfaceHidden);
}

#pragma mark Accessibility

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction
{
  if (direction == UIAccessibilityScrollDirectionLeft || direction == UIAccessibilityScrollDirectionRight) {
    if (direction == UIAccessibilityScrollDirectionLeft) {
      [[NYPLReaderSettings sharedSettings].currentReaderReadiumView openPageRight];
//      UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Next Page", @"Next Page"));
    } else if (direction == UIAccessibilityScrollDirectionRight) {
      [[NYPLReaderSettings sharedSettings].currentReaderReadiumView openPageLeft];
//      UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"Previous Page", @"Previous Page"));
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
  [self.navigationController popViewControllerAnimated:YES];
  return YES;
}

- (BOOL)accessibilityActivate
{
  NSLog(@"ACTIVATE!!");
  return YES;
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

- (void)setInterfaceHidden:(BOOL)interfaceHidden
{
  if(self.rendererView.bookIsCorrupt && interfaceHidden) {
    // Hiding the UI would prevent the user from escaping from a corrupt book.
    return;
  }
  
  _interfaceHidden = interfaceHidden;
  
  self.navigationController.interactivePopGestureRecognizer.enabled = !interfaceHidden;
  
  self.navigationController.navigationBarHidden = self.interfaceHidden;
  
  self.bottomView.hidden = self.interfaceHidden;
  
  if(self.interfaceHidden) {
    [self.readerSettingsViewPhone removeFromSuperview];
    self.readerSettingsViewPhone = nil;
  }
  
  // Accessibility
  self.rendererView.accessibilityElementsHidden = !interfaceHidden;
  id firstElement = interfaceHidden ? self.navigationItem : nil;
  UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, firstElement);
  self.largeTransparentAccessibilityButton.userInteractionEnabled = UIAccessibilityIsVoiceOverRunning() && !interfaceHidden;
  self.largeTransparentAccessibilityButton.alpha = interfaceHidden ? 0.0 : 1.0;
  self.largeTransparentAccessibilityButton.isAccessibilityElement = !interfaceHidden;
  
  [self setNeedsStatusBarAppearanceUpdate];
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

@end
