#import "NSData+NYPLDataAdditions.h"

@implementation NSData (NYPLDataAdditions)

- (NSString *)fileSystemSafeBase64EncodedString
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wassign-enum"
  return [[[[self base64EncodedStringWithOptions:0]
            stringByTrimmingCharactersInSet:[NSCharacterSet
                                             characterSetWithCharactersInString:@"="]]
           stringByReplacingOccurrencesOfString:@"+" withString:@"-"]
          stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
#pragma clang diagnostic pop
}


@end
