#import "NSMutableURLRequest+NYPLBasicAuthenticationAdditions.h"

@implementation NSMutableURLRequest (NYPLBasicAuthenticationAdditions)

- (void)setBasicAuthenticationUsername:(NSString *const)username
                              password:(NSString *const)password
{
  NSData *const authorizationData = [[NSString stringWithFormat:@"%@:%@", username, password]
                                     dataUsingEncoding:NSUTF8StringEncoding];
  
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wassign-enum"
  NSString *authorizationString = [authorizationData base64EncodedStringWithOptions:0];
#pragma clang diagnostic pop
  
  // Apple's documentation says not to do this, but there's no obvious way to handle basic auth
  // through NSURLSession without dropping down to Core Foundation classes.
  [self
   setValue:[@"Basic " stringByAppendingString:authorizationString]
   forHTTPHeaderField:@"Authorization"];
}

@end
