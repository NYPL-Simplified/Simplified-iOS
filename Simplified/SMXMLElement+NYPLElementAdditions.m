#import "SMXMLElement+NYPLElementAdditions.h"

@implementation SMXMLElement (NYPLElementAdditions)

- (NSString *)valueString
{
  if(self.value) {
    return self.value;
  }
  
  return @"";
}

@end
