#import <CommonCrypto/CommonDigest.h>

@import NYPLUtilities;

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

- (NSString *)stringURLEncodedAsQueryParamValue
{
  // chars allowed in a full query section of a url, e.g. `?k=v&k1=v1`
  NSMutableCharacterSet *noEscapingCharSet = [[NSMutableCharacterSet
                                               URLQueryAllowedCharacterSet] mutableCopy];
  // remove some of the allowed chars in a query because here we are just
  // interested in escaping a value of one query param key.
  [noEscapingCharSet removeCharactersInString:@";/?:@&=$+,"];

  // escape everything except our defined set
  return [self stringByAddingPercentEncodingWithAllowedCharacters:noEscapingCharSet];
}

- (BOOL)isEmptyNoWhitespace
{
  NSString *s = [self stringByTrimmingCharactersInSet:
                 [NSCharacterSet whitespaceAndNewlineCharacterSet]];
  return s.length == 0;
}

@end
