//
//  NSURLRequest+NYPLURLRequestAdditions.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/30/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NSURLRequest+NYPLURLRequestAdditions.h"

@implementation NSURLRequest (NYPLURLRequestAdditions)

+ (instancetype _Nonnull) postRequestWithProblemDocument:(NSDictionary * _Nonnull)problemDocument url:(NSURL * _Nonnull)url
{
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
  [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
  [request setHTTPShouldHandleCookies:NO];
  [request setTimeoutInterval:30];
  [request setHTTPMethod:@"POST"];
  
  // set Content-Type in HTTP header
  NSString *contentType = @"application/problem+json";
  [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
  
  NSData *data = [NSJSONSerialization dataWithJSONObject:problemDocument options:0 error:nil];
  [request setHTTPBody:data];
  
  // set the content-length
  NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[data length]];
  [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
  
  // set URL
  [request setURL:url];
  
  return request;
}

+ (instancetype _Nonnull) postRequestWithParams:(NSDictionary * _Nonnull)params imageOrNil:(UIImage * _Nullable)image url:(NSURL * _Nonnull)url
{
  // the boundary string : a random string, that will not repeat in post data, to separate post data fields.
  NSString *BoundaryConstant = @"----------V2ymHFg03ehbqgZCaKO6jy";
  
  // string constant for the post parameter 'file'. My server uses this name: `file`. Your's may differ
  NSString* FileParamConstant = @"file";
  
  // create request
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
  [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
  [request setHTTPShouldHandleCookies:NO];
  [request setTimeoutInterval:30];
  [request setHTTPMethod:@"POST"];
  
  // set Content-Type in HTTP header
  NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", BoundaryConstant];
  [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
  
  // post body
  NSMutableData *body = [NSMutableData data];
  
  // add params (all params are strings)
  for (NSString *param in params) {
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", param] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%@\r\n", [params objectForKey:param]] dataUsingEncoding:NSUTF8StringEncoding]];
  }
  
  // add image data
  if (image) {
    NSData *imageData = UIImageJPEGRepresentation(image, 0.7);
    if (imageData) {
      [body appendData:[[NSString stringWithFormat:@"--%@\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
      [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"image.jpg\"\r\n", FileParamConstant] dataUsingEncoding:NSUTF8StringEncoding]];
      [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
      [body appendData:imageData];
      [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }
  }
  
  [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
  
  // setting the body of the post to the reqeust
  [request setHTTPBody:body];
  
  // set the content-length
  NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[body length]];
  [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
  
  // set URL
  [request setURL:url];
  
  return request;
}
@end
