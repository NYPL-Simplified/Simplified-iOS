#import "NYPLConfiguration.h"

#import "NYPLReaderSettingsView.h"

@interface NYPLReaderSettingsView ()

@property (nonatomic) UIButton *biggerButton;
@property (nonatomic) UIButton *blackOnSepiaButton;
@property (nonatomic) UIButton *blackOnWhiteButton;
@property (nonatomic) UIImageView *brightnessHighImageView;
@property (nonatomic) UIImageView *brightnessLowImageView;
@property (nonatomic) UISlider *brightnessSlider;
@property (nonatomic) UIView *brightnessView;
@property (nonatomic) UIButton *sansButton;
@property (nonatomic) UIButton *serifButton;
@property (nonatomic) UIButton *smallerButton;
@property (nonatomic) UIButton *whiteOnBlackButton;

@end

@implementation NYPLReaderSettingsView

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if (!self) return nil;

  self.backgroundColor = [NYPLConfiguration backgroundColor];

  [self sizeToFit];

  self.sansButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.sansButton.backgroundColor = [NYPLConfiguration backgroundColor];
  [self.sansButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  [self.sansButton setTitle:@"Aa" forState:UIControlStateNormal];
  self.sansButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:24];
  [self.sansButton addTarget:self
                      action:@selector(didSelectSans)
            forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.sansButton];

  self.serifButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.serifButton.backgroundColor = [NYPLConfiguration backgroundColor];
  [self.serifButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  [self.serifButton setTitle:@"Aa" forState:UIControlStateNormal];
  self.serifButton.titleLabel.font = [UIFont fontWithName:@"Georgia" size:24];
  [self.serifButton addTarget:self
                       action:@selector(didSelectSerif)
             forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.serifButton];

  self.whiteOnBlackButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.whiteOnBlackButton.backgroundColor = [NYPLConfiguration backgroundDarkColor];
  [self.whiteOnBlackButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [self.whiteOnBlackButton setTitle:@"ABCabc" forState:UIControlStateNormal];
  self.whiteOnBlackButton.titleLabel.font = [UIFont systemFontOfSize:18];
  [self.whiteOnBlackButton addTarget:self
                              action:@selector(didSelectSerif)
                    forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.whiteOnBlackButton];

  self.blackOnSepiaButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.blackOnSepiaButton.backgroundColor = [NYPLConfiguration backgroundSepiaColor];
  [self.blackOnSepiaButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  [self.blackOnSepiaButton setTitle:@"ABCabc" forState:UIControlStateNormal];
  self.blackOnSepiaButton.titleLabel.font = [UIFont systemFontOfSize:18];
  [self.blackOnSepiaButton addTarget:self
                              action:@selector(didSelectSerif)
                    forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.blackOnSepiaButton];

  self.blackOnWhiteButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.blackOnWhiteButton.backgroundColor = [NYPLConfiguration backgroundColor];
  [self.blackOnWhiteButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  [self.blackOnWhiteButton setTitle:@"ABCabc" forState:UIControlStateNormal];
  self.blackOnWhiteButton.titleLabel.font = [UIFont systemFontOfSize:18];
  [self.blackOnWhiteButton addTarget:self
                              action:@selector(didSelectSerif)
                    forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.blackOnWhiteButton];

  self.smallerButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.smallerButton.backgroundColor = [NYPLConfiguration backgroundColor];
  [self.smallerButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  [self.smallerButton setTitle:@"A" forState:UIControlStateNormal];
  self.smallerButton.titleLabel.font = [UIFont systemFontOfSize:14];
  [self.smallerButton addTarget:self
                         action:@selector(didSelectSerif)
               forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.smallerButton];

  self.biggerButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.biggerButton.backgroundColor = [NYPLConfiguration backgroundColor];
  [self.biggerButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  [self.biggerButton setTitle:@"A" forState:UIControlStateNormal];
  self.biggerButton.titleLabel.font = [UIFont systemFontOfSize:24];
  [self.biggerButton addTarget:self
                        action:@selector(didSelectSerif)
              forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.biggerButton];

  self.brightnessView = [[UIView alloc] init];
  [self addSubview:self.brightnessView];
  
  self.brightnessLowImageView = [[UIImageView alloc]
                                 initWithImage:[UIImage imageNamed:@"BrightnessLow"]];
  [self.brightnessView addSubview:self.brightnessLowImageView];
  
  self.brightnessHighImageView = [[UIImageView alloc]
                                  initWithImage:[UIImage imageNamed:@"BrightnessHigh"]];
  [self.brightnessView addSubview:self.brightnessHighImageView];
  
  self.brightnessSlider = [[UISlider alloc] init];
  [self.brightnessSlider addTarget:self
                            action:@selector(didChangeBrightness)
                  forControlEvents:UIControlEventValueChanged];
  [self.brightnessView addSubview:self.brightnessSlider];

  [[NSNotificationCenter defaultCenter]
      addObserverForName:UIScreenBrightnessDidChangeNotification
                  object:nil
                   queue:[NSOperationQueue mainQueue]
              usingBlock:^(NSNotification *const notification) {
                self.brightnessSlider.value = ((UIScreen *) notification.object).brightness;
              }];

  self.brightnessSlider.value = [UIScreen mainScreen].brightness;

  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
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
  
  self.smallerButton.frame = CGRectMake(padding,
                                        CGRectGetMaxY(self.whiteOnBlackButton.frame),
                                        innerWidth / 2.0,
                                        CGRectGetHeight(self.frame) / 4.0);
  
  self.biggerButton.frame = CGRectMake(CGRectGetMaxX(self.smallerButton.frame),
                                       CGRectGetMaxY(self.whiteOnBlackButton.frame),
                                       innerWidth / 2.0,
                                       CGRectGetHeight(self.frame) / 4.0);
  
  self.brightnessView.frame = CGRectMake(padding,
                                         CGRectGetMaxY(self.smallerButton.frame),
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
}

- (void)drawRect:(__attribute__((unused)) CGRect)rect
{
  [self layoutIfNeeded];

  CGContextRef const c = UIGraphicsGetCurrentContext();
  CGFloat const gray[4] = {0.5, 0.5, 0.5, 1.0};
  CGContextSetStrokeColor(c, gray);

  CGContextBeginPath(c);
  CGContextMoveToPoint(c,
                       CGRectGetMinX(self.whiteOnBlackButton.frame),
                       CGRectGetMinY(self.whiteOnBlackButton.frame));
  CGContextAddLineToPoint(c,
                          CGRectGetMaxX(self.blackOnWhiteButton.frame),
                          CGRectGetMinY(self.blackOnWhiteButton.frame));
  CGContextStrokePath(c);
  
}

- (CGSize)sizeThatFits:(CGSize)size
{
  CGFloat const w = 320;
  CGFloat const h = 200;

  if (CGSizeEqualToSize(size, CGSizeZero)) {
    return CGSizeMake(w, h);
  }

  return CGSizeMake(w > size.width ? size.width : w, h > size.height ? size.height : h);
}

#pragma mark -

- (void)didSelectSans
{
  self.fontType = NYPLReaderSettingsViewFontTypeSans;

  [self.delegate readerSettingsView:self didSelectFontType:self.fontType];
}

- (void)didSelectSerif
{
  self.fontType = NYPLReaderSettingsViewFontTypeSerif;

  [self.delegate readerSettingsView:self didSelectFontType:self.fontType];
}

- (void)didChangeBrightness
{
  [self.delegate readerSettingsView:self didSelectBrightness:self.brightnessSlider.value];
}

@end
