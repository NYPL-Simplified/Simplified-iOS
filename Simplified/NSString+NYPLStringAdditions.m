#import "NSString+NYPLStringAdditions.h"

@implementation NSString (NYPLStringAdditions)

- (NSString *)fileSystemSafeBase64EncodedStringUsingEncoding:(NSStringEncoding)encoding
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wassign-enum"
  return [[[[[self dataUsingEncoding:encoding] base64EncodedStringWithOptions:0]
            stringByTrimmingCharactersInSet:[NSCharacterSet
                                             characterSetWithCharactersInString:@"="]]
           stringByReplacingOccurrencesOfString:@"+" withString:@"-"]
          stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
#pragma clang diagnostic pop
}

@end
