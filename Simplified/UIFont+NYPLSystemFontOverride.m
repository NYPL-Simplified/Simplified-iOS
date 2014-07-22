#import "NYPLConfiguration.h"

#import "UIFont+NYPLSystemFontOverride.h"

@implementation UIFont (NYPLSystemFontOverride)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

+ (UIFont *)boldSystemFontOfSize:(CGFloat)fontSize {
  return [UIFont fontWithName:[NYPLConfiguration boldSystemFontName] size:fontSize];
}

+ (UIFont *)systemFontOfSize:(CGFloat)fontSize {
  return [UIFont fontWithName:[NYPLConfiguration systemFontName] size:fontSize];
}

#pragma clang diagnostic pop

@end