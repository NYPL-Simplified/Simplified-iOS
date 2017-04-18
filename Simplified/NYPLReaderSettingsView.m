#import "NYPLConfiguration.h"

#import "NYPLReaderSettingsView.h"
#import "NYPLReaderReadiumView.h"

@interface NYPLReaderSettingsView ()

@property (nonatomic) UIButton *blackOnSepiaButton;
@property (nonatomic) UIButton *blackOnWhiteButton;
@property (nonatomic) UIImageView *brightnessHighImageView;
@property (nonatomic) UIImageView *brightnessLowImageView;
@property (nonatomic) UISlider *brightnessSlider;
@property (nonatomic) UIView *brightnessView;
@property (nonatomic) UIButton *decreaseButton;
@property (nonatomic) UIButton *increaseButton;
@property (nonatomic) NSMutableArray *lineViews;
@property (nonatomic) NSMutableArray *observers;
@property (nonatomic) UIButton *sansButton;
@property (nonatomic) UIButton *serifButton;
@property (nonatomic) UIButton *openDyslexicButton;
@property (nonatomic) UIButton *whiteOnBlackButton;
@property (nonatomic) UIButton *mediaOverlayButton;
@property (nonatomic) BOOL mediaOverlayToggle;

@end

@implementation NYPLReaderSettingsView

#pragma mark NSObject

- (instancetype)initWithWidth:(CGFloat const)width
{
  self = [super init];
  if (!self) return nil;
  
  CGSize const size = [self sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
  self.frame = CGRectMake(0, 0, size.width, size.height);

  self.observers = [NSMutableArray array];
  
  self.backgroundColor = [NYPLConfiguration backgroundColor];

  [self sizeToFit];

  NSDictionary *underlineAttribute = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)};
  NSDictionary *noUnderlineAttribute = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone)};
  
  self.sansButton = [UIButton buttonWithType:UIButtonTypeCustom];
  
  
  self.sansButton.accessibilityLabel = [[NSString alloc] initWithFormat:NSLocalizedString(@"SansFont", nil)];
  self.sansButton.backgroundColor = [NYPLConfiguration backgroundColor];
  [self.sansButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  self.sansButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:24];
  [self.sansButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Aa"
                                                                      attributes:noUnderlineAttribute] forState:UIControlStateNormal];
  
  [self.sansButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Aa"
                                                                      attributes:underlineAttribute] forState:UIControlStateDisabled];
  
  [self.sansButton addTarget:self
                      action:@selector(didSelectSans)
            forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.sansButton];

  
  self.serifButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.serifButton.accessibilityLabel = [[NSString alloc] initWithFormat:NSLocalizedString(@"SerifFont", nil)];
  self.serifButton.backgroundColor = [NYPLConfiguration backgroundColor];
  [self.serifButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  self.serifButton.titleLabel.font = [UIFont fontWithName:@"Georgia" size:24];
  [self.serifButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Aa"
                                                                      attributes:noUnderlineAttribute] forState:UIControlStateNormal];
  
  [self.serifButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Aa"
                                                                      attributes:underlineAttribute] forState:UIControlStateDisabled];

  
  [self.serifButton addTarget:self
                       action:@selector(didSelectSerif)
             forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.serifButton];
  
  
  self.openDyslexicButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.openDyslexicButton.accessibilityLabel = [[NSString alloc] initWithFormat:NSLocalizedString(@"OpenDyslexicFont", nil)];
  self.openDyslexicButton.backgroundColor = [NYPLConfiguration backgroundColor];
  [self.openDyslexicButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  self.openDyslexicButton.titleLabel.font = [UIFont fontWithName:@"OpenDyslexic3" size:20];
  [self.openDyslexicButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Aa"
                                                                       attributes:noUnderlineAttribute] forState:UIControlStateNormal];
  
  [self.openDyslexicButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Aa"
                                                                       attributes:underlineAttribute] forState:UIControlStateDisabled];

  [self.openDyslexicButton setTitleEdgeInsets:UIEdgeInsetsMake(-4.0f, 0.0f, 0.0f, 0.0f)];
  [self.openDyslexicButton addTarget:self
                       action:@selector(didSelectOpenDyslexic)
             forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.openDyslexicButton];

  self.whiteOnBlackButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.whiteOnBlackButton.accessibilityLabel = [[NSString alloc] initWithFormat:NSLocalizedString(@"WhiteOnBlackText", nil)];
  self.whiteOnBlackButton.backgroundColor = [NYPLConfiguration backgroundDarkColor];
  
  NSDictionary *whiteColourWithoutUnderline = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone), NSForegroundColorAttributeName : [UIColor whiteColor] };
  NSDictionary *whiteColourWithUnderline = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle), NSForegroundColorAttributeName : [UIColor whiteColor] };
  
  [self.whiteOnBlackButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"ABCabc"
                                                                              attributes:whiteColourWithoutUnderline] forState:UIControlStateNormal];
  
  [self.whiteOnBlackButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"ABCabc"
                                                                              attributes:whiteColourWithUnderline] forState:UIControlStateDisabled];
  
  self.whiteOnBlackButton.titleLabel.font = [UIFont systemFontOfSize:18];
  [self.whiteOnBlackButton addTarget:self
                              action:@selector(didSelectWhiteOnBlack)
                    forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.whiteOnBlackButton];

  self.blackOnSepiaButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.blackOnSepiaButton.accessibilityLabel = [[NSString alloc] initWithFormat:NSLocalizedString(@"BlackOnSepiaText", nil)];
  self.blackOnSepiaButton.backgroundColor = [NYPLConfiguration backgroundSepiaColor];
  [self.blackOnSepiaButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  [self.blackOnSepiaButton setTitleColor:[NYPLConfiguration mainColor]
                                forState:UIControlStateDisabled];
  
  [self.blackOnSepiaButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"ABCabc"
                                                                              attributes:noUnderlineAttribute] forState:UIControlStateNormal];
  
  [self.blackOnSepiaButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"ABCabc"
                                                                              attributes:underlineAttribute] forState:UIControlStateDisabled];
  self.blackOnSepiaButton.titleLabel.font = [UIFont systemFontOfSize:18];
  [self.blackOnSepiaButton addTarget:self
                              action:@selector(didSelectBlackOnSepia)
                    forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.blackOnSepiaButton];

  self.blackOnWhiteButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.blackOnWhiteButton.accessibilityLabel = [[NSString alloc] initWithFormat:NSLocalizedString(@"BlackOnWhiteText", nil)];
  self.blackOnWhiteButton.backgroundColor = [NYPLConfiguration backgroundColor];
  [self.blackOnWhiteButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  [self.blackOnWhiteButton setTitleColor:[NYPLConfiguration mainColor]
                                forState:UIControlStateDisabled];
  
  [self.blackOnWhiteButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"ABCabc"
                                                                              attributes:noUnderlineAttribute] forState:UIControlStateNormal];
  
  [self.blackOnWhiteButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"ABCabc"
                                                                              attributes:underlineAttribute] forState:UIControlStateDisabled];
  self.blackOnWhiteButton.titleLabel.font = [UIFont systemFontOfSize:18];
  [self.blackOnWhiteButton addTarget:self
                              action:@selector(didSelectBlackOnWhite)
                    forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.blackOnWhiteButton];

  self.decreaseButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.decreaseButton.accessibilityLabel = [[NSString alloc] initWithFormat:NSLocalizedString(@"DecreaseFontSize", nil)];
  self.decreaseButton.backgroundColor = [NYPLConfiguration backgroundColor];
  [self.decreaseButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  [self.decreaseButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
  [self.decreaseButton setTitle:@"A" forState:UIControlStateNormal];
  self.decreaseButton.titleLabel.font = [UIFont systemFontOfSize:14];
  [self.decreaseButton addTarget:self
                          action:@selector(didSelectDecrease)
                forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.decreaseButton];

  self.increaseButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.increaseButton.accessibilityLabel = [[NSString alloc] initWithFormat:NSLocalizedString(@"IncreaseFontSize", nil)];
  [self.increaseButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  [self.increaseButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
  [self.increaseButton setTitle:@"A" forState:UIControlStateNormal];
  self.increaseButton.titleLabel.font = [UIFont systemFontOfSize:24];
  [self.increaseButton addTarget:self
                          action:@selector(didSelectIncrease)
                forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.increaseButton];

  self.brightnessView = [[UIView alloc] init];
  [self addSubview:self.brightnessView];
  
  self.mediaOverlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.mediaOverlayButton.accessibilityLabel = [[NSString alloc] initWithFormat:NSLocalizedString(@"MediaOverlayPlaybackToggle", nil)];
  self.mediaOverlayButton.backgroundColor = [NYPLConfiguration backgroundColor];
  self.mediaOverlayToggle = NO;
  
  [self.mediaOverlayButton setImage:  [[UIImage imageNamed:@"IconButtonVolumeOff"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
  
  [self.mediaOverlayButton addTarget:self
                              action:@selector(didSelectMediaOverlayToggle)
                    forControlEvents:UIControlEventTouchUpInside];
  [self.brightnessView addSubview:self.mediaOverlayButton];
  
  if ([NYPLReaderSettings sharedSettings].currentReaderReadiumView) {
    
    if ([[NYPLReaderSettings sharedSettings].currentReaderReadiumView bookHasMediaOverlays]) {
      self.mediaOverlayButton.userInteractionEnabled = YES;
      self.mediaOverlayButton.alpha = 1.0;
      
      if ([[NYPLReaderSettings sharedSettings].currentReaderReadiumView bookHasMediaOverlaysBeingPlayed]) {
        self.mediaOverlayToggle = YES;
        [self.mediaOverlayButton setImage:  [[UIImage imageNamed:@"IconButtonVolumeOn"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
      }
      else {
        self.mediaOverlayToggle = NO;
        [self.mediaOverlayButton setImage:  [[UIImage imageNamed:@"IconButtonVolumeOff"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
      }
    }
    else {
      self.mediaOverlayButton.userInteractionEnabled = NO;
      self.mediaOverlayButton.alpha = 0.3;
    }
  }
  
  self.brightnessLowImageView = [[UIImageView alloc]
                                 initWithImage:[[UIImage imageNamed:@"BrightnessLow"]
                                                imageWithRenderingMode:
                                                UIImageRenderingModeAlwaysTemplate]];
  [self.brightnessView addSubview:self.brightnessLowImageView];
  
  self.brightnessHighImageView = [[UIImageView alloc]
                                  initWithImage:[[UIImage imageNamed:@"BrightnessHigh"]
                                                 imageWithRenderingMode:
                                                 UIImageRenderingModeAlwaysTemplate]];
  [self.brightnessView addSubview:self.brightnessHighImageView];
  
  self.brightnessSlider = [[UISlider alloc] init];
  self.brightnessSlider.accessibilityLabel = [[NSString alloc] initWithFormat:NSLocalizedString(@"BrightnessSlider", nil)];
  [self.brightnessSlider addTarget:self
                            action:@selector(didChangeBrightness)
                  forControlEvents:UIControlEventValueChanged];
  [self.brightnessView addSubview:self.brightnessSlider];

  [self.observers addObject:
   [[NSNotificationCenter defaultCenter]
    addObserverForName:UIScreenBrightnessDidChangeNotification
    object:nil
    queue:[NSOperationQueue mainQueue]
    usingBlock:^(NSNotification *const notification) {
      self.brightnessSlider.value = ((UIScreen *) notification.object).brightness;
    }]];

  self.brightnessSlider.value = [UIScreen mainScreen].brightness;

  return self;
}

- (void)dealloc
{
  for(id observer in self.observers) {
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
  }
}

#pragma mark UIView

- (void)layoutSubviews
{
  CGFloat const padding = 20;
  CGFloat const innerWidth = CGRectGetWidth(self.frame) - padding * 2;
  
  self.sansButton.frame = CGRectMake(padding,
                                        0,
                                     round(innerWidth / 3.0),
                                     CGRectGetHeight(self.frame) / 4.0);
  
  self.serifButton.frame = CGRectMake(CGRectGetMaxX(self.sansButton.frame),
                                      0,
                                      round(innerWidth / 3.0),
                                      CGRectGetHeight(self.frame) / 4.0);

  self.openDyslexicButton.frame = CGRectMake(CGRectGetMaxX(self.serifButton.frame),
                                      0,
                                      round(innerWidth / 3.0),
                                      CGRectGetHeight(self.frame) / 4.0);
  
  self.whiteOnBlackButton.frame = CGRectMake(padding,
                                             CGRectGetMaxY(self.serifButton.frame),
                                             round(innerWidth / 3.0),
                                             CGRectGetHeight(self.frame) / 4.0);
  
  self.blackOnSepiaButton.frame = CGRectMake(CGRectGetMaxX(self.whiteOnBlackButton.frame),
                                             CGRectGetMaxY(self.serifButton.frame),
                                             round(innerWidth / 3.0),
                                             CGRectGetHeight(self.frame) / 4.0);
  
  self.blackOnWhiteButton.frame = CGRectMake(CGRectGetMaxX(self.blackOnSepiaButton.frame),
                                             CGRectGetMaxY(self.serifButton.frame),
                                             (CGRectGetWidth(self.frame) - padding -
                                              CGRectGetMaxX(self.blackOnSepiaButton.frame)),
                                             CGRectGetHeight(self.frame) / 4.0);
  
  self.decreaseButton.frame = CGRectMake(padding,
                                         CGRectGetMaxY(self.whiteOnBlackButton.frame),
                                         innerWidth / 2.0,
                                         CGRectGetHeight(self.frame) / 4.0);
  
  self.increaseButton.frame = CGRectMake(CGRectGetMaxX(self.decreaseButton.frame),
                                         CGRectGetMaxY(self.whiteOnBlackButton.frame),
                                         innerWidth / 2.0,
                                         CGRectGetHeight(self.frame) / 4.0);
  
  self.brightnessView.frame = CGRectMake(padding,
                                         CGRectGetMaxY(self.decreaseButton.frame),
                                         innerWidth,
                                         CGRectGetHeight(self.frame) / 4.0);
  
  
  CGRect mediaOverlayButtonLineToItsRight = CGRectMake(self.brightnessView.frame.size.width / 4,
                                                   CGRectGetMinY(self.brightnessView.frame),
                                                   1,
                                                   CGRectGetHeight(self.brightnessView.frame));
  
  float spaceWidth = mediaOverlayButtonLineToItsRight.origin.x - self.brightnessView.frame.origin.x;
  
  CGSize mediaOverlayButtonSize = CGSizeMake(36, 32);
  self.mediaOverlayButton.frame =  CGRectMake( (spaceWidth / 2) - mediaOverlayButtonSize.width / 2,
                                              (self.brightnessView.frame.size.height / 2) - (mediaOverlayButtonSize.height / 2),
                                              mediaOverlayButtonSize.width,
                                              mediaOverlayButtonSize.height);
  
  self.brightnessLowImageView.frame =
    CGRectMake(mediaOverlayButtonLineToItsRight.origin.x,
               (CGRectGetHeight(self.brightnessView.frame) / 2 -
                CGRectGetHeight(self.brightnessLowImageView.frame) / 2),
               CGRectGetWidth(self.brightnessLowImageView.frame),
               CGRectGetHeight(self.brightnessLowImageView.frame));
  
  self.brightnessHighImageView.frame =
    CGRectMake((CGRectGetWidth(self.brightnessView.frame) -
                CGRectGetWidth(self.brightnessHighImageView.frame)),
               (CGRectGetHeight(self.brightnessView.frame) / 2 -
                CGRectGetHeight(self.brightnessHighImageView.frame) / 2),
               CGRectGetWidth(self.brightnessHighImageView.frame),
               CGRectGetHeight(self.brightnessHighImageView.frame));
  
  [self.brightnessSlider sizeToFit];
  CGFloat const sliderPadding = padding / 2.0;
  CGFloat const brightnessSliderWidth =
    (CGRectGetMinX(self.brightnessHighImageView.frame)
     - CGRectGetMaxX(self.brightnessLowImageView.frame)
     - sliderPadding * 2);
  
  self.brightnessSlider.frame = CGRectMake(CGRectGetMaxX(self.brightnessLowImageView.frame) + sliderPadding,
                                           (CGRectGetHeight(self.brightnessView.frame) / 2 -
                                            CGRectGetHeight(self.brightnessSlider.frame) / 2),
                                           brightnessSliderWidth,
                                           CGRectGetHeight(self.brightnessSlider.frame));
  
  [self updateLineViews];
}

- (CGSize)sizeThatFits:(CGSize)size
{
  CGFloat const defaultWidth = 320;
  CGFloat const defaultHeight = 200;

  if(CGSizeEqualToSize(size, CGSizeZero)) {
    return CGSizeMake(defaultWidth, defaultHeight);
  }
  
  CGFloat const aspectRatio = defaultWidth / defaultHeight;

  if(size.width / size.height > aspectRatio) {
    return CGSizeMake(size.height * aspectRatio, size.height);
  } else {
    return CGSizeMake(size.width, size.width / aspectRatio);
  }
}

#pragma mark -

- (void)setFontFace:(NYPLReaderSettingsFontFace)fontFace
{
  _fontFace = fontFace;
  
  switch(fontFace) {
    case NYPLReaderSettingsFontFaceSans:
      self.sansButton.enabled = NO;
      self.serifButton.enabled = YES;
      self.openDyslexicButton.enabled = YES;
      break;
    case NYPLReaderSettingsFontFaceSerif:
      self.sansButton.enabled = YES;
      self.serifButton.enabled = NO;
      self.openDyslexicButton.enabled = YES;
      break;
    case NYPLReaderSettingsFontFaceOpenDyslexic:
      self.sansButton.enabled = YES;
      self.serifButton.enabled = YES;
      self.openDyslexicButton.enabled = NO;
      break;
  }
}

- (void)setFontSize:(NYPLReaderSettingsFontSize const)fontSize
{
  _fontSize = fontSize;
  
  switch(fontSize) {
    case NYPLReaderSettingsFontSizeSmallest:
      self.decreaseButton.enabled = NO;
      self.increaseButton.enabled = YES;
      break;
    case NYPLReaderSettingsFontSizeXXXLarge:
      self.decreaseButton.enabled = YES;
      self.increaseButton.enabled = NO;
      break;
    case NYPLReaderSettingsFontSizeSmaller:
      // fallthrough
    case NYPLReaderSettingsFontSizeSmall:
      // fallthrough
    case NYPLReaderSettingsFontSizeNormal:
      // fallthrough
    case NYPLReaderSettingsFontSizeLarge:
      // fallthrough
    case NYPLReaderSettingsFontSizeXLarge:
      // fallthrough
    case NYPLReaderSettingsFontSizeXXLarge:
      self.decreaseButton.enabled = YES;
      self.increaseButton.enabled = YES;
      break;
  }
}

- (void)setColorScheme:(NYPLReaderSettingsColorScheme const)colorScheme
{
  _colorScheme = colorScheme;
  
  UIColor *backgroundColor;
  UIColor *foregroundColor;
  
  switch(colorScheme) {
    case NYPLReaderSettingsColorSchemeBlackOnSepia:
      self.blackOnSepiaButton.enabled = NO;
      self.blackOnWhiteButton.enabled = YES;
      self.whiteOnBlackButton.enabled = YES;
      backgroundColor = [NYPLConfiguration backgroundSepiaColor];
      foregroundColor = [UIColor blackColor];
      break;
    case NYPLReaderSettingsColorSchemeBlackOnWhite:
      self.blackOnSepiaButton.enabled = YES;
      self.blackOnWhiteButton.enabled = NO;
      self.whiteOnBlackButton.enabled = YES;
      backgroundColor = [NYPLConfiguration backgroundColor];
      foregroundColor = [UIColor blackColor];
      break;
    case NYPLReaderSettingsColorSchemeWhiteOnBlack:
      self.blackOnSepiaButton.enabled = YES;
      self.blackOnWhiteButton.enabled = YES;
      self.whiteOnBlackButton.enabled = NO;
      backgroundColor = [NYPLConfiguration backgroundDarkColor];
      foregroundColor = [UIColor whiteColor];
      break;
  }
  
  self.backgroundColor = backgroundColor;
  
  self.mediaOverlayButton.backgroundColor = backgroundColor;
  self.mediaOverlayButton.tintColor = foregroundColor;
  
  [self.brightnessHighImageView setTintColor:foregroundColor];
  [self.brightnessLowImageView setTintColor:foregroundColor];
  
  self.decreaseButton.backgroundColor = backgroundColor;
  [self.decreaseButton setTitleColor:foregroundColor forState:UIControlStateNormal];
  
  self.increaseButton.backgroundColor = backgroundColor;
  [self.increaseButton setTitleColor:foregroundColor forState:UIControlStateNormal];
  
  
  NSDictionary *fontColourWithUnderline = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle), NSForegroundColorAttributeName : foregroundColor };
  NSDictionary *fontColourWithoutUnderline = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone), NSForegroundColorAttributeName : foregroundColor };
  
  [self.sansButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Aa"
                                                                      attributes:fontColourWithoutUnderline] forState:UIControlStateNormal];
  
  [self.sansButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Aa"
                                                                      attributes:fontColourWithUnderline] forState:UIControlStateDisabled];
  
  self.sansButton.backgroundColor = backgroundColor;
  
  self.serifButton.backgroundColor = backgroundColor;
  [self.serifButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Aa"
                                                                       attributes:fontColourWithoutUnderline] forState:UIControlStateNormal];
  
  [self.serifButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Aa"
                                                                       attributes:fontColourWithUnderline] forState:UIControlStateDisabled];
  
  
  self.openDyslexicButton.backgroundColor = backgroundColor;
  [self.openDyslexicButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Aa"
                                                                              attributes:fontColourWithoutUnderline] forState:UIControlStateNormal];
  
  [self.openDyslexicButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Aa"
                                                                              attributes:fontColourWithUnderline] forState:UIControlStateDisabled];
  
  
  NSDictionary *underlineAttribute = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)};
  NSDictionary *noUnderlineAttribute = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone)};
  NSDictionary *whiteColourWithUnderline = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle), NSForegroundColorAttributeName : [UIColor whiteColor] };
  NSDictionary *whiteColourWithoutUnderline = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone), NSForegroundColorAttributeName : [UIColor whiteColor] };
  
  [self.whiteOnBlackButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"ABCabc"
                                                                              attributes:whiteColourWithoutUnderline] forState:UIControlStateNormal];
  
  [self.whiteOnBlackButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"ABCabc"
                                                                              attributes:whiteColourWithUnderline] forState:UIControlStateDisabled];
  
  [self.blackOnSepiaButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"ABCabc"
                                                                              attributes:noUnderlineAttribute] forState:UIControlStateNormal];
  
  [self.blackOnSepiaButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"ABCabc"
                                                                              attributes:underlineAttribute] forState:UIControlStateDisabled];
  
  [self.blackOnWhiteButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"ABCabc"
                                                                              attributes:noUnderlineAttribute] forState:UIControlStateNormal];
  
  [self.blackOnWhiteButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"ABCabc"
                                                                              attributes:underlineAttribute] forState:UIControlStateDisabled];
}

- (void)didSelectSans
{
  self.fontFace = NYPLReaderSettingsFontFaceSans;

  [self.delegate readerSettingsView:self didSelectFontFace:self.fontFace];
}

- (void)didSelectSerif
{
  self.fontFace = NYPLReaderSettingsFontFaceSerif;

  [self.delegate readerSettingsView:self didSelectFontFace:self.fontFace];
}

- (void)didSelectOpenDyslexic
{
  self.fontFace = NYPLReaderSettingsFontFaceOpenDyslexic;
  
  [self.delegate readerSettingsView:self didSelectFontFace:self.fontFace];
}

- (void)didSelectMediaOverlayToggle
{
  [self.delegate readerSettingsViewDidSelectMediaOverlayToggle:self];
  
  if (self.mediaOverlayToggle) {
    self.mediaOverlayToggle = NO;
    [self.mediaOverlayButton setImage:  [[UIImage imageNamed:@"IconButtonVolumeOff"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
  }
  else {
    self.mediaOverlayToggle = YES;
    [self.mediaOverlayButton setImage:  [[UIImage imageNamed:@"IconButtonVolumeOn"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
  }
}

- (void)didChangeBrightness
{
  [self.delegate readerSettingsView:self didSelectBrightness:self.brightnessSlider.value];
}

- (void)didSelectWhiteOnBlack
{
  self.colorScheme = NYPLReaderSettingsColorSchemeWhiteOnBlack;
  
  [self.delegate readerSettingsView:self didSelectColorScheme:self.colorScheme];
}

- (void)didSelectBlackOnWhite
{
  self.colorScheme = NYPLReaderSettingsColorSchemeBlackOnWhite;
  
  [self.delegate readerSettingsView:self didSelectColorScheme:self.colorScheme];
}

- (void)didSelectBlackOnSepia
{
  self.colorScheme = NYPLReaderSettingsColorSchemeBlackOnSepia;
  
  [self.delegate readerSettingsView:self didSelectColorScheme:self.colorScheme];
}

- (void)didSelectDecrease
{
  NYPLReaderSettingsFontSize newFontSize;
  
  if(!NYPLReaderSettingsDecreasedFontSize(self.fontSize, &newFontSize)) {
    NYPLLOG(@"Ignorning attempt to set font size below the minimum.");
    return;
  }
  
  self.fontSize = newFontSize;
  
  [self.delegate readerSettingsView:self didSelectFontSize:self.fontSize];
}

- (void)didSelectIncrease
{
  NYPLReaderSettingsFontSize newFontSize;
  
  if(!NYPLReaderSettingsIncreasedFontSize(self.fontSize, &newFontSize)) {
    NYPLLOG(@"Ignorning attempt to set font size above the maximum.");
    return;
  }
  
  self.fontSize = newFontSize;
  
  [self.delegate readerSettingsView:self didSelectFontSize:self.fontSize];
}

- (void)updateLineViews
{
  for(UIView *const lineView in self.lineViews) {
    [lineView removeFromSuperview];
  }
  
  [self.lineViews removeAllObjects];
  
  CGFloat const thin = 1.0 / [UIScreen mainScreen].scale;
  
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone
      ) {
    UIView *const line = [[UIView alloc]
                          initWithFrame:CGRectMake(CGRectGetMinX(self.sansButton.frame),
                                                   CGRectGetMinY(self.sansButton.frame),
                                                   (CGRectGetMaxX(self.openDyslexicButton.frame) -
                                                   CGRectGetMinX(self.sansButton.frame)),
                                                   thin)];
    [line setBackgroundColor:[UIColor lightGrayColor]];
    [self addSubview:line];
  }
    
  {
    UIView *const line = [[UIView alloc]
                          initWithFrame:CGRectMake(CGRectGetMinX(self.openDyslexicButton.frame),
                                                   CGRectGetMinY(self.openDyslexicButton.frame),
                                                   thin,
                                                   CGRectGetHeight(self.openDyslexicButton.frame))];
    [line setBackgroundColor:[UIColor lightGrayColor]];
    [self addSubview:line];
  }

  {
    UIView *const line = [[UIView alloc]
                           initWithFrame:CGRectMake(CGRectGetMinX(self.whiteOnBlackButton.frame),
                                                    CGRectGetMinY(self.whiteOnBlackButton.frame),
                                                    (CGRectGetMaxX(self.blackOnWhiteButton.frame) -
                                                     CGRectGetMinX(self.whiteOnBlackButton.frame)),
                                                    thin)];
    [line setBackgroundColor:[UIColor lightGrayColor]];
    [self addSubview:line];
  }
  
  {
    UIView *const line = [[UIView alloc]
                          initWithFrame:CGRectMake(CGRectGetMinX(self.decreaseButton.frame),
                                                   CGRectGetMinY(self.decreaseButton.frame),
                                                   (CGRectGetMaxX(self.increaseButton.frame)
                                                    - CGRectGetMinX(self.decreaseButton.frame)),
                                                   thin)];
    [line setBackgroundColor:[UIColor lightGrayColor]];
    [self addSubview:line];
  }
  
  {
    UIView *const line = [[UIView alloc]
                          initWithFrame:CGRectMake(CGRectGetMinX(self.brightnessView.frame),
                                                   CGRectGetMinY(self.brightnessView.frame),
                                                   CGRectGetWidth(self.brightnessView.frame),
                                                   thin)];
    [line setBackgroundColor:[UIColor lightGrayColor]];
    [self addSubview:line];
  }
  
  {
    UIView *const line = [[UIView alloc]
                          initWithFrame:CGRectMake(CGRectGetMinX(self.serifButton.frame),
                                                   CGRectGetMinY(self.serifButton.frame),
                                                   thin,
                                                   CGRectGetHeight(self.serifButton.frame))];
    [line setBackgroundColor:[UIColor lightGrayColor]];
    [self addSubview:line];
  }
  
  {
    UIView *const line = [[UIView alloc]
                          initWithFrame:CGRectMake(CGRectGetMinX(self.blackOnSepiaButton.frame),
                                                   CGRectGetMinY(self.blackOnSepiaButton.frame),
                                                   thin,
                                                   CGRectGetHeight(self.blackOnSepiaButton.frame))];
    [line setBackgroundColor:[UIColor lightGrayColor]];
    [self addSubview:line];
  }

  {
    UIView *const line = [[UIView alloc]
                          initWithFrame:CGRectMake(CGRectGetMinX(self.blackOnWhiteButton.frame),
                                                   CGRectGetMinY(self.blackOnWhiteButton.frame),
                                                   thin,
                                                   CGRectGetHeight(self.blackOnWhiteButton.frame))];
    [line setBackgroundColor:[UIColor lightGrayColor]];
    [self addSubview:line];
  }
  
  {
    UIView *const line = [[UIView alloc]
                          initWithFrame:CGRectMake(CGRectGetMinX(self.increaseButton.frame),
                                                   CGRectGetMinY(self.increaseButton.frame),
                                                   thin,
                                                   CGRectGetHeight(self.increaseButton.frame))];
    [line setBackgroundColor:[UIColor lightGrayColor]];
    [self addSubview:line];
  }
  
  {
    UIView *const line = [[UIView alloc]
                          initWithFrame:CGRectMake(self.brightnessView.frame.size.width / 4,
                                                   CGRectGetMinY(self.brightnessView.frame),
                                                   thin,
                                                   CGRectGetHeight(self.brightnessView.frame))];
    [line setBackgroundColor:[UIColor lightGrayColor]];
    [self addSubview:line];
  }
}

@end
