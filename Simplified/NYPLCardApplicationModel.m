//
//  NYPLCardApplicationModel.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/6/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLCardApplicationModel.h"
#import <CommonCrypto/CommonDigest.h>

#define kNYPLCardApplicationModel     @"CardApplicationModel"
#define kNYPLCardApplicationDOB       @"DateOfBirth"
#define kNYPLCardApplicaitonInNYState @"IsInNYState"

NSString *md5HexDigest(NSString *input) {
  const char* str = [input UTF8String];
  unsigned char result[CC_MD5_DIGEST_LENGTH];
  CC_MD5(str, (CC_LONG) strlen(str), result);
  
  NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];
  for(int i = 0; i<CC_MD5_DIGEST_LENGTH; i++) {
    [ret appendFormat:@"%02x",result[i]];
  }
  return ret;
}

@interface NYPLCardApplicationModel ()
@property (nonatomic, assign) NYPLAssetUploadState applicationUploadState, photoUploadState;
@end

@implementation NYPLCardApplicationModel
- (id) initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
    self.applicationUploadState = NYPLAssetUploadStateUnknown;
    self.photoUploadState = NYPLAssetUploadStateUnknown;
    self.dob = (NSDate *) [aDecoder decodeObjectForKey:kNYPLCardApplicationDOB];
    self.isInNYState = [aDecoder decodeBoolForKey:kNYPLCardApplicaitonInNYState];
  }
  return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
  [aCoder encodeObject:self.dob forKey:kNYPLCardApplicationDOB];
  [aCoder encodeBool:self.isInNYState forKey:kNYPLCardApplicaitonInNYState];
}

- (NSURL *) apiURL
{
  return [NSURL URLWithString:@"https://simplifiedcard.herokuapp.com/"];
}

- (void)setPhoto:(UIImage *)photo
{
  BOOL needsUpload = NO;
  if (self.photo != photo)
    needsUpload = (photo != nil);
  _photo = photo;
  if (needsUpload)
    self.photoUploadState = NYPLAssetUploadStateUnknown;
}

- (void)uploadPhoto {
  // from: http://stackoverflow.com/a/8567771/160933
  
  self.photoUploadState = NYPLAssetUploadStateUploading;
  NSString *timeString = [NSString stringWithFormat:@"%f", [NSDate timeIntervalSinceReferenceDate]];
  NSString *uniqueName = [NSString stringWithFormat:@"ios-%@.jpg", md5HexDigest(timeString)];
  self.awsPhotoName = uniqueName;
  
  // Dictionary that holds post parameters. You can set your post parameters that your server accepts or programmed to accept.
  NSMutableDictionary* _params = [[NSMutableDictionary alloc] init];
  [_params setObject:uniqueName forKey:@"name"];
  NSLog(@"Unique name: %@", uniqueName);
  
  // the boundary string : a random string, that will not repeat in post data, to separate post data fields.
  NSString *BoundaryConstant = @"----------V2ymHFg03ehbqgZCaKO6jy";
  
  // string constant for the post parameter 'file'. My server uses this name: `file`. Your's may differ
  NSString* FileParamConstant = @"file";
  
  // the server url to which the image (or the media) is uploaded. Use your server url here
  NSURL *requestURL = [self.apiURL URLByAppendingPathComponent:@"upload"];
  
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
  for (NSString *param in _params) {
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", param] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%@\r\n", [_params objectForKey:param]] dataUsingEncoding:NSUTF8StringEncoding]];
  }
  
  // add image data
  NSData *imageData = UIImageJPEGRepresentation(self.photo, 0.7);
  if (imageData) {
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"image.jpg\"\r\n", FileParamConstant] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:imageData];
    [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
  }
  
  [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
  
  // setting the body of the post to the reqeust
  [request setHTTPBody:body];
  
  // set the content-length
  NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[body length]];
  [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
  
  // set URL
  [request setURL:requestURL];
  
  NSURLSession *session = [NSURLSession sharedSession];
  NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(__attribute__((unused))NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
    if (error || [(NSHTTPURLResponse *)response statusCode] != 200) {
      self.photoUploadState = NYPLAssetUploadStateError;
    } else {
      self.photoUploadState = NYPLAssetUploadStateComplete;
    }
  }];
  [task resume];
}

- (void)uploadApplication
{
  // Dictionary that holds post parameters. You can set your post parameters that your server accepts or programmed to accept.
  NSMutableDictionary* _params = [[NSMutableDictionary alloc] init];
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:@"yyyy-MM-dd"];
  [_params setObject:[NSString stringWithFormat:@"%@, %@", self.lastName, self.firstName] forKey:@"name"];
  [_params setObject:self.address forKey:@"address"];
  [_params setObject:[formatter stringFromDate:self.dob] forKey:@"birthdate"];
  [_params setObject:self.email forKey:@"email"];
  [_params setObject:self.awsPhotoName forKey:@"filename_id"];
  [_params setObject:self.awsPhotoName forKey:@"filename_guardian_signature"];
  [_params setObject:self.awsPhotoName forKey:@"filename_guardian_id"];
  [_params setObject:(self.isInNYState ? @"true" : @"false") forKey:@"geofence"];
  
  // the boundary string : a random string, that will not repeat in post data, to separate post data fields.
  NSString *BoundaryConstant = @"----------V2ymHFg03ehbqgZCaKO6jy";
  
  // the server url to which the image (or the media) is uploaded. Use your server url here
  NSURL *requestURL = [self.apiURL URLByAppendingPathComponent:@"create_patron"];
  
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
  for (NSString *param in _params) {
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", param] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%@\r\n", [_params objectForKey:param]] dataUsingEncoding:NSUTF8StringEncoding]];
  }
  
  [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
  
  // setting the body of the post to the reqeust
  [request setHTTPBody:body];
  
  // set the content-length
  NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[body length]];
  [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
  
  // set URL
  [request setURL:requestURL];
  
  NSURLSession *session = [NSURLSession sharedSession];
  NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(__attribute__((unused))NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
    if (error || [(NSHTTPURLResponse *)response statusCode] != 200) {
      self.applicationUploadState = NYPLAssetUploadStateError;
    } else {
      self.applicationUploadState = NYPLAssetUploadStateComplete;
    }
  }];
  [task resume];
}

@end
