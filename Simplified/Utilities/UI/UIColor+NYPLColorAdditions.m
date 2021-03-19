#import "UIColor+NYPLColorAdditions.h"

@implementation UIColor (NYPLColorAdditions)

- (NSString *)javascriptHexString
{
  CGFloat red, green, blue, alpha;
  
  [self getRed:&red green:&green blue:&blue alpha:&alpha];
  
  uint8_t const r = round(red * 255.0);
  uint8_t const g = round(green * 255.0);
  uint8_t const b = round(blue * 255.0);
  
  return [NSString stringWithFormat:@"#%02X%02X%02X", r, g, b];
}

@end
