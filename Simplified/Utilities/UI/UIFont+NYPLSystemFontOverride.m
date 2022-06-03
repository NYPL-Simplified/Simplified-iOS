#import "UIFont+NYPLSystemFontOverride.h"
#import "SimplyE-Swift.h"

@implementation UIFont (NYPLSystemFontOverride)

+ (UIFont *)customFontForTextStyle:(UIFontTextStyle)style
{
  return [self customFontForTextStyle:style multiplier:1.0];
}

+ (UIFont *)customFontForTextStyle:(UIFontTextStyle)style multiplier:(CGFloat)multiplier {
  UIFont *preferredFont = [UIFont preferredFontForTextStyle:style];
  NSDictionary *traitDict = [(NSDictionary *)preferredFont.fontDescriptor objectForKey:UIFontDescriptorTraitsAttribute];
  NSNumber *weight = traitDict[UIFontWeightTrait];
  
  NSDictionary *attributes = @{UIFontDescriptorTraitsAttribute:@{UIFontWeightTrait:weight}};
  UIFontDescriptor *newDescriptor = [[[UIFontDescriptor fontDescriptorWithName:preferredFont.fontName
                                                                          size:preferredFont.pointSize]
                                                      fontDescriptorWithFamily:[NYPLConfiguration systemFontFamilyName]]
                                              fontDescriptorByAddingAttributes:attributes];
  
  return [UIFont fontWithDescriptor:newDescriptor size:preferredFont.pointSize * multiplier];
}

+ (UIFont *)customBoldFontForTextStyle:(UIFontTextStyle)style {
  UIFont *preferredFont = [UIFont preferredFontForTextStyle:style];
  NSDictionary *attributes = @{UIFontDescriptorTraitsAttribute:@{UIFontWeightTrait:@(UIFontWeightBold)}};
  UIFontDescriptor *newDescriptor = [[[UIFontDescriptor fontDescriptorWithName:preferredFont.fontName
                                                                          size:preferredFont.pointSize]
                                      fontDescriptorWithFamily:[NYPLConfiguration systemFontFamilyName]]
                                     fontDescriptorByAddingAttributes:attributes];
  
  return [UIFont fontWithDescriptor:newDescriptor size:preferredFont.pointSize];
}

@end
