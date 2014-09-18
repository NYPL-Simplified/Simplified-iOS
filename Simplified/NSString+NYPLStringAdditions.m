#import "NSString+NYPLStringAdditions.h"

@implementation NSString (NYPLStringAdditions)

- (NSString *)fileSystemSafeBase64DecodedStringUsingEncoding:(NSStringEncoding)encoding
{
  NSMutableString *const s = [[[self stringByReplacingOccurrencesOfString:@"-" withString:@"+"]
                               stringByReplacingOccurrencesOfString:@"_" withString:@"/"]
                              mutableCopy];
  
  while([s length] % 4) {
    [s appendString:@"="];
  }
  
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wassign-enum"
  return [[NSString alloc]
          initWithData:[[NSData alloc] initWithBase64EncodedString:s options:0]
          encoding:encoding];
#pragma clang diagnostic pop
}

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

- (NSString *)stringByURLEncoding
{
  CFStringRef const s = CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                (__bridge CFStringRef)self,
                                                                NULL,
                                                                CFSTR(";/?:@&=$+{}<>,"),
                                                                kCFStringEncodingUTF8);
  
  return CFBridgingRelease(s);
}

@end
