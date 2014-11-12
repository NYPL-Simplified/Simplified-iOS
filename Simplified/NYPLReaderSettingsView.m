#import "NYPLReaderSettingsView.h"

@implementation NYPLReaderSettingsView

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.backgroundColor = [UIColor lightGrayColor];
  
  [self sizeToFit];
  
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

- (CGSize)sizeThatFits:(CGSize)size
{
  CGFloat const w = 320;
  CGFloat const h = 200;
  
  if(CGSizeEqualToSize(size, CGSizeZero)) {
    return CGSizeMake(w, h);
  }
  
  return CGSizeMake(w > size.width ? size.width : w, h > size.height ? size.height : h);
}

@end
