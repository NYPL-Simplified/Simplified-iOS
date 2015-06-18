#import "NYPLConfiguration.h"

#import "NYPLReaderSettingsView.h"

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
@property (nonatomic) UIButton *whiteOnBlackButton;

@end

@implementation NYPLReaderSettingsView

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if (!self) return nil;

  self.observers = [NSMutableArray array];
  
  self.backgroundColor = [NYPLConfiguration backgroundColor];

  [self sizeToFit];

  self.sansButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.sansButton.backgroundColor = [NYPLConfiguration backgroundColor];
  [self.sansButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  [self.sansButton setTitleColor:[NYPLConfiguration mainColor] forState:UIControlStateDisabled];
  [self.sansButton setTitle:@"Aa" forState:UIControlStateNormal];
  self.sansButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:24];
  [self.sansButton addTarget:self
                      action:@selector(didSelectSans)
            forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.sansButton];

  self.serifButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.serifButton.backgroundColor = [NYPLConfiguration backgroundColor];
  [self.serifButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  [self.serifButton setTitleColor:[NYPLConfiguration mainColor] forState:UIControlStateDisabled];
  [self.serifButton setTitle:@"Aa" forState:UIControlStateNormal];
  self.serifButton.titleLabel.font = [UIFont fontWithName:@"Georgia" size:24];
  [self.serifButton addTarget:self
                       action:@selector(didSelectSerif)
             forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.serifButton];

  self.whiteOnBlackButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.whiteOnBlackButton.backgroundColor = [NYPLConfiguration backgroundDarkColor];
  [self.whiteOnBlackButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [self.whiteOnBlackButton setTitleColor:[NYPLConfiguration mainColor]
                                forState:UIControlStateDisabled];
  [self.whiteOnBlackButton setTitle:@"ABCabc" forState:UIControlStateNormal];
  self.whiteOnBlackButton.titleLabel.font = [UIFont systemFontOfSize:18];
  [self.whiteOnBlackButton addTarget:self
                              action:@selector(didSelectWhiteOnBlack)
                    forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.whiteOnBlackButton];

  self.blackOnSepiaButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.blackOnSepiaButton.backgroundColor = [NYPLConfiguration backgroundSepiaColor];
  [self.blackOnSepiaButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  [self.blackOnSepiaButton setTitleColor:[NYPLConfiguration mainColor]
                                forState:UIControlStateDisabled];
  [self.blackOnSepiaButton setTitle:@"ABCabc" forState:UIControlStateNormal];
  self.blackOnSepiaButton.titleLabel.font = [UIFont systemFontOfSize:18];
  [self.blackOnSepiaButton addTarget:self
                              action:@selector(didSelectBlackOnSepia)
                    forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.blackOnSepiaButton];

  self.blackOnWhiteButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.blackOnWhiteButton.backgroundColor = [NYPLConfiguration backgroundColor];
  [self.blackOnWhiteButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  [self.blackOnWhiteButton setTitleColor:[NYPLConfiguration mainColor]
                                forState:UIControlStateDisabled];
  [self.blackOnWhiteButton setTitle:@"ABCabc" forState:UIControlStateNormal];
  self.blackOnWhiteButton.titleLabel.font = [UIFont systemFontOfSize:18];
  [self.blackOnWhiteButton addTarget:self
                              action:@selector(didSelectBlackOnWhite)
                    forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.blackOnWhiteButton];

  self.decreaseButton = [UIButton buttonWithType:UIButtonTypeCustom];
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
  self.increaseButton.backgroundColor = [NYPLConfiguration backgroundColor];
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
                                     innerWidth / 2.0,
                                     CGRectGetHeight(self.frame) / 4.0);
  
  self.serifButton.frame = CGRectMake(CGRectGetWidth(self.frame) / 2.0,
                                      0,
                                      innerWidth / 2.0,
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
  
  self.brightnessLowImageView.frame =
    CGRectMake(padding,
               (CGRectGetHeight(self.brightnessView.frame) / 2 -
                CGRectGetHeight(self.brightnessLowImageView.frame) / 2),
               CGRectGetWidth(self.brightnessLowImageView.frame),
               CGRectGetHeight(self.brightnessLowImageView.frame));
  
  self.brightnessHighImageView.frame =
    CGRectMake((CGRectGetWidth(self.brightnessView.frame) - padding -
                CGRectGetWidth(self.brightnessHighImageView.frame)),
               (CGRectGetHeight(self.brightnessView.frame) / 2 -
                CGRectGetHeight(self.brightnessHighImageView.frame) / 2),
               CGRectGetWidth(self.brightnessHighImageView.frame),
               CGRectGetHeight(self.brightnessHighImageView.frame));
  
  [self.brightnessSlider sizeToFit];
  CGFloat const sliderPadding = 5;
  CGFloat const brightnessSliderWidth =
    ((CGRectGetMinX(self.brightnessHighImageView.frame) -
      CGRectGetWidth(self.brightnessView.frame) / 2)
     * 2
     - sliderPadding * 2);
  
  self.brightnessSlider.frame = CGRectMake((CGRectGetWidth(self.brightnessView.frame) / 2 -
                                            brightnessSliderWidth / 2),
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
      break;
    case NYPLReaderSettingsFontFaceSerif:
      self.sansButton.enabled = YES;
      self.serifButton.enabled = NO;
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
    case NYPLReaderSettingsFontSizeLargest:
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
    case NYPLReaderSettingsFontSizeLarger:
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
  
  [self.brightnessHighImageView setTintColor:foregroundColor];
  [self.brightnessLowImageView setTintColor:foregroundColor];
  
  self.decreaseButton.backgroundColor = backgroundColor;
  [self.decreaseButton setTitleColor:foregroundColor forState:UIControlStateNormal];
  
  self.increaseButton.backgroundColor = backgroundColor;
  [self.increaseButton setTitleColor:foregroundColor forState:UIControlStateNormal];
  
  self.sansButton.backgroundColor = backgroundColor;
  [self.sansButton setTitleColor:foregroundColor forState:UIControlStateNormal];
  
  self.serifButton.backgroundColor = backgroundColor;
  [self.serifButton setTitleColor:foregroundColor forState:UIControlStateNormal];
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
}

@end
