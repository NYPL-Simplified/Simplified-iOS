#import "NYPLConfiguration.h"

#import "NYPLReaderSettingsView.h"
#import "SimplyE-Swift.h"

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
@property (nonatomic) UIStackView *publisherDefaultContainer;
@property (nonatomic) UILabel *publisherDefaultLabel;
@property (nonatomic) UISwitch *publisherDefaultSwitch;

@end

@implementation NYPLReaderSettingsView

#pragma mark NSObject

- (instancetype)initWithWidth:(CGFloat const)width
{
  self = [super init];
  if (!self) return nil;
  
  self.observers = [NSMutableArray array];
  CGSize const size = [self sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
  self.frame = CGRectMake(0, 0, size.width, size.height);
  self.backgroundColor = [NYPLConfiguration backgroundColor];
  [self sizeToFit];

   // font family --------------------------------------------------------------
  NSDictionary *underlineAttribute = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)};
  NSDictionary *noUnderlineAttribute = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone)};
  
  self.sansButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.sansButton.accessibilityLabel = [[NSString alloc] initWithFormat:NSLocalizedString(@"SansFont", nil)];
  self.sansButton.backgroundColor = [NYPLConfiguration backgroundColor];
  [self.sansButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  self.sansButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:24];
  [self.sansButton
   setAttributedTitle:[[NSAttributedString alloc]
                       initWithString:NSLocalizedString(@"AlphabetFontType", nil)
                       attributes:noUnderlineAttribute]
   forState:UIControlStateNormal];
  [self.sansButton
   setAttributedTitle:[[NSAttributedString alloc]
                       initWithString:NSLocalizedString(@"AlphabetFontType", nil)
                       attributes:underlineAttribute]
   forState:UIControlStateDisabled];
  
  [self.sansButton addTarget:self
                      action:@selector(didSelectSans)
            forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.sansButton];

  self.serifButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.serifButton.accessibilityLabel = [[NSString alloc] initWithFormat:NSLocalizedString(@"SerifFont", nil)];
  self.serifButton.backgroundColor = [NYPLConfiguration backgroundColor];
  [self.serifButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  self.serifButton.titleLabel.font = [UIFont fontWithName:@"Georgia" size:24];
  [self.serifButton
   setAttributedTitle:[[NSAttributedString alloc]
                       initWithString:NSLocalizedString(@"AlphabetFontType", nil)
                       attributes:noUnderlineAttribute]
   forState:UIControlStateNormal];
  [self.serifButton
   setAttributedTitle:[[NSAttributedString alloc]
                       initWithString:NSLocalizedString(@"AlphabetFontType", nil)
                       attributes:underlineAttribute]
   forState:UIControlStateDisabled];

  [self.serifButton addTarget:self
                       action:@selector(didSelectSerif)
             forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.serifButton];

  self.openDyslexicButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.openDyslexicButton.accessibilityLabel = [[NSString alloc] initWithFormat:NSLocalizedString(@"OpenDyslexicFont", nil)];
  self.openDyslexicButton.backgroundColor = [NYPLConfiguration backgroundColor];
  [self.openDyslexicButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  self.openDyslexicButton.titleLabel.font = [UIFont fontWithName:@"OpenDyslexic3" size:20];
  [self.openDyslexicButton
   setAttributedTitle:[[NSAttributedString alloc]
                       initWithString:NSLocalizedString(@"AlphabetFontType", nil)
                       attributes:noUnderlineAttribute]
   forState:UIControlStateNormal];
  [self.openDyslexicButton
   setAttributedTitle:[[NSAttributedString alloc]
                       initWithString:NSLocalizedString(@"AlphabetFontType", nil)
                       attributes:underlineAttribute]
   forState:UIControlStateDisabled];
  [self.openDyslexicButton setTitleEdgeInsets:UIEdgeInsetsMake(-4.0f, 0.0f, 0.0f, 0.0f)];
  [self.openDyslexicButton addTarget:self
                       action:@selector(didSelectOpenDyslexic)
             forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.openDyslexicButton];


  // background color ----------------------------------------------------------
  const CGFloat fontSize = 18;
  self.whiteOnBlackButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.whiteOnBlackButton.accessibilityLabel = [[NSString alloc] initWithFormat:NSLocalizedString(@"WhiteOnBlackText", nil)];
  self.whiteOnBlackButton.backgroundColor = [NYPLConfiguration readerBackgroundDarkColor];
  
  NSDictionary *whiteColourWithoutUnderline = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone), NSForegroundColorAttributeName : [UIColor whiteColor] };
  NSDictionary *whiteColourWithUnderline = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle), NSForegroundColorAttributeName : [UIColor whiteColor] };
  
  [self.whiteOnBlackButton
   setAttributedTitle:[[NSAttributedString alloc]
                       initWithString:NSLocalizedString(@"AlphabetFontStyle", nil)
                       attributes:whiteColourWithoutUnderline]
   forState:UIControlStateNormal];
  [self.whiteOnBlackButton
   setAttributedTitle:[[NSAttributedString alloc]
                       initWithString:NSLocalizedString(@"AlphabetFontStyle", nil)
                       attributes:whiteColourWithUnderline]
   forState:UIControlStateDisabled];
  self.whiteOnBlackButton.titleLabel.font = [UIFont systemFontOfSize:fontSize];
  [self.whiteOnBlackButton addTarget:self
                              action:@selector(didSelectWhiteOnBlack)
                    forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.whiteOnBlackButton];

  self.blackOnSepiaButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.blackOnSepiaButton.accessibilityLabel = [[NSString alloc] initWithFormat:NSLocalizedString(@"BlackOnSepiaText", nil)];
  self.blackOnSepiaButton.backgroundColor = [NYPLConfiguration readerBackgroundSepiaColor];
  [self.blackOnSepiaButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  [self.blackOnSepiaButton setTitleColor:[NYPLConfiguration mainColor]
                                forState:UIControlStateDisabled];
  
  [self.blackOnSepiaButton setAttributedTitle:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"AlphabetFontStyle", nil)
                                                                              attributes:noUnderlineAttribute] forState:UIControlStateNormal];
  
  [self.blackOnSepiaButton setAttributedTitle:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"AlphabetFontStyle", nil)
                                                                              attributes:underlineAttribute] forState:UIControlStateDisabled];
  self.blackOnSepiaButton.titleLabel.font = [UIFont systemFontOfSize:fontSize];
  [self.blackOnSepiaButton addTarget:self
                              action:@selector(didSelectBlackOnSepia)
                    forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.blackOnSepiaButton];

  self.blackOnWhiteButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.blackOnWhiteButton.accessibilityLabel = [[NSString alloc] initWithFormat:NSLocalizedString(@"BlackOnWhiteText", nil)];
  self.blackOnWhiteButton.backgroundColor = [NYPLConfiguration readerBackgroundColor];
  [self.blackOnWhiteButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  [self.blackOnWhiteButton setTitleColor:[NYPLConfiguration mainColor]
                                forState:UIControlStateDisabled];
  
  [self.blackOnWhiteButton setAttributedTitle:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"AlphabetFontStyle", nil)
                                                                              attributes:noUnderlineAttribute] forState:UIControlStateNormal];
  
  [self.blackOnWhiteButton setAttributedTitle:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"AlphabetFontStyle", nil)
                                                                              attributes:underlineAttribute] forState:UIControlStateDisabled];
  self.blackOnWhiteButton.titleLabel.font = [UIFont systemFontOfSize:fontSize];
  [self.blackOnWhiteButton addTarget:self
                              action:@selector(didSelectBlackOnWhite)
                    forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.blackOnWhiteButton];


  // font size -----------------------------------------------------------------
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


  // publisher's default -------------------------------------------------------
  self.publisherDefaultLabel = [[UILabel alloc] init];
  self.publisherDefaultLabel.text = NSLocalizedString(@"Publisher's Defaults", nil);
  self.publisherDefaultLabel.font = [UIFont systemFontOfSize:fontSize];
  self.publisherDefaultLabel.allowsDefaultTighteningForTruncation = YES;
  self.publisherDefaultLabel.numberOfLines = 1;

  self.publisherDefaultSwitch = [[UISwitch alloc] init];
  self.publisherDefaultSwitch.onTintColor = NYPLConfiguration.mainColor;
  [self.publisherDefaultSwitch addTarget:self
                                  action:@selector(didTogglePublisherDefault)
                        forControlEvents:UIControlEventTouchUpInside];

  self.publisherDefaultContainer = [[UIStackView alloc]
                                    initWithArrangedSubviews:@[self.publisherDefaultLabel,
                                                               self.publisherDefaultSwitch]];
  self.publisherDefaultContainer.axis = UILayoutConstraintAxisHorizontal;
  self.publisherDefaultContainer.distribution = UIStackViewDistributionFill;
  self.publisherDefaultContainer.spacing = 10;
  self.publisherDefaultContainer.alignment = UIStackViewAlignmentCenter;
#if OPENEBOOKS
  self.publisherDefaultContainer.hidden = YES;
#endif
  [self addSubview:self.publisherDefaultContainer];

  // brightness slider ---------------------------------------------------------
  self.brightnessView = [[UIView alloc] init];
  [self addSubview:self.brightnessView];
  
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
  [super layoutSubviews];

  CGFloat const padding = 10;
  CGFloat const topPadding = 16;
  CGFloat const innerWidth = CGRectGetWidth(self.frame) - padding * 2;
#if OPENEBOOKS
  CGFloat const numRows = 4.0;
#else
  CGFloat const numRows = 5.0;
#endif

  CGFloat const rowHeight = round((CGRectGetHeight(self.frame) - topPadding) / numRows);

#if OPENEBOOKS
  CGFloat const publisherDefaultsRowHeight = 0;
#else
  CGFloat const publisherDefaultsRowHeight = rowHeight;
#endif

  self.sansButton.frame = CGRectMake(padding,
                                     topPadding,
                                     round(innerWidth / 3.0),
                                     rowHeight);
  
  self.serifButton.frame = CGRectMake(CGRectGetMaxX(self.sansButton.frame),
                                      topPadding,
                                      round(innerWidth / 3.0),
                                      rowHeight);

  self.openDyslexicButton.frame = CGRectMake(CGRectGetMaxX(self.serifButton.frame),
                                             topPadding,
                                             round(innerWidth / 3.0),
                                             rowHeight);
  
  self.whiteOnBlackButton.frame = CGRectMake(padding,
                                             CGRectGetMaxY(self.serifButton.frame),
                                             round(innerWidth / 3.0),
                                             rowHeight);
  
  self.blackOnSepiaButton.frame = CGRectMake(CGRectGetMaxX(self.whiteOnBlackButton.frame),
                                             CGRectGetMaxY(self.serifButton.frame),
                                             round(innerWidth / 3.0),
                                             rowHeight);
  
  self.blackOnWhiteButton.frame = CGRectMake(CGRectGetMaxX(self.blackOnSepiaButton.frame),
                                             CGRectGetMaxY(self.serifButton.frame),
                                             (CGRectGetWidth(self.frame) - padding -
                                              CGRectGetMaxX(self.blackOnSepiaButton.frame)),
                                             rowHeight);
  
  self.decreaseButton.frame = CGRectMake(padding,
                                         CGRectGetMaxY(self.whiteOnBlackButton.frame),
                                         innerWidth / 2.0,
                                         rowHeight);
  
  self.increaseButton.frame = CGRectMake(CGRectGetMaxX(self.decreaseButton.frame),
                                         CGRectGetMaxY(self.whiteOnBlackButton.frame),
                                         innerWidth / 2.0,
                                         rowHeight);

  self.publisherDefaultContainer.frame = CGRectMake(padding,
                                                    CGRectGetMaxY(self.increaseButton.frame),
                                                    innerWidth,
                                                    publisherDefaultsRowHeight);

  self.brightnessView.frame = CGRectMake(padding,
                                         CGRectGetMaxY(self.publisherDefaultContainer.frame),
                                         innerWidth,
                                         rowHeight);

  self.brightnessLowImageView.frame =
    CGRectMake(0,
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
  CGFloat const defaultHeight = 295;

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
      backgroundColor = [NYPLConfiguration readerBackgroundSepiaColor];
      foregroundColor = [UIColor blackColor];
      break;
    case NYPLReaderSettingsColorSchemeBlackOnWhite:
      self.blackOnSepiaButton.enabled = YES;
      self.blackOnWhiteButton.enabled = NO;
      self.whiteOnBlackButton.enabled = YES;
      backgroundColor = [NYPLConfiguration readerBackgroundColor];
      foregroundColor = [UIColor blackColor];
      break;
    case NYPLReaderSettingsColorSchemeWhiteOnBlack:
      self.blackOnSepiaButton.enabled = YES;
      self.blackOnWhiteButton.enabled = YES;
      self.whiteOnBlackButton.enabled = NO;
      backgroundColor = [NYPLConfiguration readerBackgroundDarkColor];
      foregroundColor = [UIColor whiteColor];
      break;
  }
  
  self.backgroundColor = backgroundColor;
  
  [self.brightnessHighImageView setTintColor:foregroundColor];
  [self.brightnessLowImageView setTintColor:foregroundColor];
  
  self.decreaseButton.backgroundColor = backgroundColor;
  [self.decreaseButton setTitleColor:foregroundColor forState:UIControlStateNormal];
  
  self.increaseButton.backgroundColor = backgroundColor;
  [self.increaseButton setTitleColor:foregroundColor forState:UIControlStateNormal];
  
  
  NSDictionary *fontColourWithUnderline = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle), NSForegroundColorAttributeName : foregroundColor };
  NSDictionary *fontColourWithoutUnderline = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone), NSForegroundColorAttributeName : foregroundColor };
  
  [self.sansButton setAttributedTitle:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"AlphabetFontType", nil)
                                                                      attributes:fontColourWithoutUnderline] forState:UIControlStateNormal];
  
  [self.sansButton setAttributedTitle:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"AlphabetFontType", nil)
                                                                      attributes:fontColourWithUnderline] forState:UIControlStateDisabled];
  
  self.sansButton.backgroundColor = backgroundColor;
  
  self.serifButton.backgroundColor = backgroundColor;
  [self.serifButton setAttributedTitle:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"AlphabetFontType", nil)
                                                                       attributes:fontColourWithoutUnderline] forState:UIControlStateNormal];
  
  [self.serifButton setAttributedTitle:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"AlphabetFontType", nil)
                                                                       attributes:fontColourWithUnderline] forState:UIControlStateDisabled];
  
  
  self.openDyslexicButton.backgroundColor = backgroundColor;
  [self.openDyslexicButton setAttributedTitle:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"AlphabetFontType", nil)
                                                                              attributes:fontColourWithoutUnderline] forState:UIControlStateNormal];
  
  [self.openDyslexicButton setAttributedTitle:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"AlphabetFontType", nil)
                                                                              attributes:fontColourWithUnderline] forState:UIControlStateDisabled];
  
  
  NSDictionary *blackColourWithUnderline = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle), NSForegroundColorAttributeName : [UIColor blackColor] };
  NSDictionary *blackColourWithoutUnderline = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone), NSForegroundColorAttributeName : [UIColor blackColor] };
  NSDictionary *whiteColourWithUnderline = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle), NSForegroundColorAttributeName : [UIColor whiteColor] };
  NSDictionary *whiteColourWithoutUnderline = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone), NSForegroundColorAttributeName : [UIColor whiteColor] };
  
  [self.whiteOnBlackButton setAttributedTitle:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"AlphabetFontStyle", nil)
                                                                              attributes:whiteColourWithoutUnderline] forState:UIControlStateNormal];
  
  [self.whiteOnBlackButton setAttributedTitle:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"AlphabetFontStyle", nil)
                                                                              attributes:whiteColourWithUnderline] forState:UIControlStateDisabled];
  
  [self.blackOnSepiaButton setAttributedTitle:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"AlphabetFontStyle", nil)
                                                                              attributes:blackColourWithoutUnderline] forState:UIControlStateNormal];
  
  [self.blackOnSepiaButton setAttributedTitle:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"AlphabetFontStyle", nil)
                                                                              attributes:blackColourWithUnderline] forState:UIControlStateDisabled];
  
  [self.blackOnWhiteButton setAttributedTitle:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"AlphabetFontStyle", nil)
                                                                              attributes:blackColourWithoutUnderline] forState:UIControlStateNormal];
  
  [self.blackOnWhiteButton setAttributedTitle:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"AlphabetFontStyle", nil)
                                                                              attributes:blackColourWithUnderline] forState:UIControlStateDisabled];

  self.publisherDefaultLabel.textColor = foregroundColor;
  self.publisherDefaultLabel.backgroundColor = backgroundColor;
}

- (void)setPublisherDefault:(BOOL)publisherDefault
{
  _publisherDefault = publisherDefault;
  self.publisherDefaultSwitch.on = publisherDefault;
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
  if (self.fontSize == NYPLReaderSettingsFontSizeSmallest) {
    NYPLLOG(@"Ignoring attempt to set font size below the minimum.");
    return;
  }

  self.fontSize = [self.delegate
                   readerSettingsView:self
                   didChangeFontSize:NYPLReaderFontSizeChangeDecrease];
}

- (void)didSelectIncrease
{
  if (self.fontSize == NYPLReaderSettingsFontSizeXXXLarge) {
    NYPLLOG(@"Ignoring attempt to set font size above the max.");
    return;
  }

  self.fontSize = [self.delegate
                   readerSettingsView:self
                   didChangeFontSize:NYPLReaderFontSizeChangeIncrease];
}

- (void)didTogglePublisherDefault
{
  self.publisherDefault = !self.publisherDefault;
  
  [self.delegate readerSettingsView:self
         didChangePublisherDefaults:self.publisherDefault];
}

- (void)updateLineViews
{
  for(UIView *const lineView in self.lineViews) {
    [lineView removeFromSuperview];
  }
  
  [self.lineViews removeAllObjects];
  
  CGFloat const thin = 1.0 / [UIScreen mainScreen].scale;

  // horizontal lines

  {
    UIView *const line = [[UIView alloc] initWithFrame:
                          CGRectMake(CGRectGetMinX(self.openDyslexicButton.frame),
                                     CGRectGetMinY(self.openDyslexicButton.frame),
                                     thin,
                                     CGRectGetHeight(self.openDyslexicButton.frame))];
    [line setBackgroundColor:[UIColor lightGrayColor]];
    [self addSubview:line];
  }

  {
    UIView *const line = [[UIView alloc] initWithFrame:
                          CGRectMake(CGRectGetMinX(self.whiteOnBlackButton.frame),
                                     CGRectGetMinY(self.whiteOnBlackButton.frame),
                                     (CGRectGetMaxX(self.blackOnWhiteButton.frame) -
                                      CGRectGetMinX(self.whiteOnBlackButton.frame)),
                                     thin)];
    [line setBackgroundColor:[UIColor lightGrayColor]];
    [self addSubview:line];
  }
  
  {
    UIView *const line = [[UIView alloc] initWithFrame:
                          CGRectMake(CGRectGetMinX(self.decreaseButton.frame),
                                     CGRectGetMinY(self.decreaseButton.frame),
                                     (CGRectGetMaxX(self.increaseButton.frame)
                                      - CGRectGetMinX(self.decreaseButton.frame)),
                                     thin)];
    [line setBackgroundColor:[UIColor lightGrayColor]];
    [self addSubview:line];
  }
  
  {
    UIView *const line = [[UIView alloc] initWithFrame:
                          CGRectMake(CGRectGetMinX(self.brightnessView.frame),
                                     CGRectGetMinY(self.brightnessView.frame),
                                     CGRectGetWidth(self.brightnessView.frame),
                                     thin)];
    [line setBackgroundColor:[UIColor lightGrayColor]];
    [self addSubview:line];
  }

  {
    UIView *const line = [[UIView alloc] initWithFrame:
                          CGRectMake(CGRectGetMinX(self.brightnessView.frame),
                                     CGRectGetMinY(self.publisherDefaultContainer.frame),
                                     CGRectGetWidth(self.brightnessView.frame),
                                     thin)];
    [line setBackgroundColor:[UIColor lightGrayColor]];
    [self addSubview:line];
  }

  // vertical lines

  {
    UIView *const line = [[UIView alloc] initWithFrame:
                          CGRectMake(CGRectGetMinX(self.serifButton.frame),
                                     CGRectGetMinY(self.serifButton.frame),
                                     thin,
                                     CGRectGetHeight(self.serifButton.frame))];
    [line setBackgroundColor:[UIColor lightGrayColor]];
    [self addSubview:line];
  }
  
  {
    UIView *const line = [[UIView alloc] initWithFrame:
                          CGRectMake(CGRectGetMinX(self.blackOnSepiaButton.frame),
                                     CGRectGetMinY(self.blackOnSepiaButton.frame),
                                     thin,
                                     CGRectGetHeight(self.blackOnSepiaButton.frame))];
    [line setBackgroundColor:[UIColor lightGrayColor]];
    [self addSubview:line];
  }

  {
    UIView *const line = [[UIView alloc] initWithFrame:
                          CGRectMake(CGRectGetMinX(self.blackOnWhiteButton.frame),
                                     CGRectGetMinY(self.blackOnWhiteButton.frame),
                                     thin,
                                     CGRectGetHeight(self.blackOnWhiteButton.frame))];
    [line setBackgroundColor:[UIColor lightGrayColor]];
    [self addSubview:line];
  }
  
  {
    UIView *const line = [[UIView alloc] initWithFrame:
                          CGRectMake(CGRectGetMinX(self.increaseButton.frame),
                                     CGRectGetMinY(self.increaseButton.frame),
                                     thin,
                                     CGRectGetHeight(self.increaseButton.frame))];
    [line setBackgroundColor:[UIColor lightGrayColor]];
    [self addSubview:line];
  }
}

@end
