#import "NYPLConfiguration.h"

#import "NYPLReaderSettingsView.h"

@interface NYPLReaderSettingsView ()

@property (nonatomic) UIButton *sansButton;
@property (nonatomic) UIButton *serifButton;

@end

@implementation NYPLReaderSettingsView

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.backgroundColor = [UIColor lightGrayColor];
  
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
  
  [[NSNotificationCenter defaultCenter]
   addObserverForName:UIScreenBrightnessDidChangeNotification
   object:nil
   queue:[NSOperationQueue mainQueue]
   usingBlock:^(NSNotification *const notification) {
     self.brightness = ((UIScreen *) notification.object).brightness;
   }];
  
  self.brightness = [UIScreen mainScreen].brightness;
  
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark UIView

- (void)layoutSubviews
{
  self.sansButton.frame = CGRectMake(0,
                                     0,
                                     CGRectGetWidth(self.frame) / 2.0,
                                     CGRectGetHeight(self.frame) / 4.0);
  
  self.serifButton.frame = CGRectMake(CGRectGetWidth(self.frame) / 2.0,
                                      0,
                                      CGRectGetWidth(self.frame) / 2.0,
                                      CGRectGetHeight(self.frame) / 4.0);
}

- (CGSize)sizeThatFits:(CGSize)size
{
  CGFloat const w = 320;
  CGFloat const h = 200;
  
  if(CGSizeEqualToSize(size, CGSizeZero)) {
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

@end
