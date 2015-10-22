//
//  NYPLCardApplicationModel.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/6/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLCardApplicationModel.h"
#import "NYPLAccount.h"
#import "NYPLKeychain.h"
#import "NYPLSettings.h"
#import "NYPLConfiguration.h"
#import <CommonCrypto/CommonDigest.h>

static NSString *const kNYPLCardApplicationModel =                @"NYPLCardApplicationModel";
static NSString *const kNYPLCardApplicationDOB =                  @"NYPLCardApplicationDOB";
static NSString *const kNYPLCardApplicationIsInNYState =          @"NYPLCardApplicationIsInNYState";
static NSString *const kNYPLCardApplicationFirstName =            @"NYPLCardApplicationFirstName";
static NSString *const kNYPLCardApplicationLastName =             @"NYPLCardApplicationLastName";
static NSString *const kNYPLCardApplicationAddress =              @"NYPLCardApplicationAddress";
static NSString *const kNYPLCardApplicationEmail =                @"NYPLCardApplicationEmail";
static NSString *const kNYPLCardApplicationAWSPhotoName =         @"NYPLCardApplicationAWSPhotoName";
static NSString *const kNYPLCardApplicationPhotoUploaded =        @"NYPLCardApplicationPhotoUploaded";
static NSString *const kNYPLCardApplicationApplicationUploaded =  @"NYPLCardApplicationApplicationUploaded";

static NYPLCardApplicationModel *s_currentApplication = nil;

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
@property (nonatomic, assign) NYPLAccount *sharedAccount;
@property (nonatomic, assign) NYPLKeychain *sharedKeychain;
@property (nonatomic, strong) NSString *barcode, *patron_id;
@property (nonatomic, assign) NSInteger pin, ptype, transaction_id;
@property (nonatomic, assign) NYPLAssetUploadState applicationUploadState, photoUploadState;
@property (nonatomic, assign) NSURLSessionDataTask *applicationUploadTask;
@end

@implementation NYPLCardApplicationModel

+ (NYPLCardApplicationModel *) currentCardApplication
{
  if (s_currentApplication == nil)
    s_currentApplication = [[NYPLSettings sharedSettings] currentCardApplication];
  return s_currentApplication;
}

+ (NYPLCardApplicationModel *) beginCardApplication
{
  NSAssert(s_currentApplication == nil, @"NYPLCardApplicationModel: Tried to begin a new application with one already in progress");
  
  s_currentApplication = [[NYPLCardApplicationModel alloc] init];
  return s_currentApplication;
}

+ (void) clearCurrentApplication
{
  s_currentApplication = nil;
  [[NYPLSettings sharedSettings] setCurrentCardApplication:nil];
}

// According to http://stackoverflow.com/questions/20344255/secitemadd-and-secitemcopymatching-returns-error-code-34018-errsecmissingentit/22305193#22305193
//  sometimes the keychain will throw error -34018 if you try to use it too soon after initializing it. Creating them as soon as
//  we initialize the card application guarantees that they will be ready when we need them
- (void)sharedInit
{
  self.sharedAccount = [NYPLAccount sharedAccount];
  self.sharedKeychain = [NYPLKeychain sharedKeychain];
}

- (id) init
{
  self = [super init];
  if (self) {
    [self sharedInit];
  }
  return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
    [self sharedInit];
    
    self.dob = (NSDate *) [aDecoder decodeObjectForKey:kNYPLCardApplicationDOB];
    _photo = [self restoreLocalPhoto];
    self.awsPhotoName = [aDecoder decodeObjectForKey:kNYPLCardApplicationAWSPhotoName];
    self.isInNYState = [aDecoder decodeBoolForKey:kNYPLCardApplicationIsInNYState];
    self.firstName = [aDecoder decodeObjectForKey:kNYPLCardApplicationFirstName];
    self.lastName = [aDecoder decodeObjectForKey:kNYPLCardApplicationLastName];
    self.address = [aDecoder decodeObjectForKey:kNYPLCardApplicationAddress];
    self.email = [aDecoder decodeObjectForKey:kNYPLCardApplicationEmail];
    self.applicationUploadState = [aDecoder decodeIntegerForKey:kNYPLCardApplicationApplicationUploaded];
    self.photoUploadState = [aDecoder decodeIntegerForKey:kNYPLCardApplicationPhotoUploaded];
    
    if (self.photoUploadState != NYPLAssetUploadStateComplete)
      [self uploadPhoto];
  }
  return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
  if (self.photo)
    [self savePhotoLocally];
  
  [aCoder encodeObject:self.dob forKey:kNYPLCardApplicationDOB];
  [aCoder encodeObject:self.awsPhotoName forKey:kNYPLCardApplicationAWSPhotoName];
  [aCoder encodeBool:self.isInNYState forKey:kNYPLCardApplicationIsInNYState];
  [aCoder encodeObject:self.firstName forKey:kNYPLCardApplicationFirstName];
  [aCoder encodeObject: self.lastName forKey:kNYPLCardApplicationLastName];
  [aCoder encodeObject:self.address forKey:kNYPLCardApplicationAddress];
  [aCoder encodeObject:self.email forKey:kNYPLCardApplicationEmail];
  [aCoder encodeInteger:self.applicationUploadState forKey:kNYPLCardApplicationApplicationUploaded];
  [aCoder encodeInteger:self.photoUploadState forKey:kNYPLCardApplicationPhotoUploaded];
}

- (void) savePhotoLocally
{
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
  
  NSData *binaryImageData = UIImagePNGRepresentation(self.photo);
  [binaryImageData writeToFile:[documentsDirectory stringByAppendingPathComponent:@"app-photo.png"] atomically:YES];
}

- (UIImage *) restoreLocalPhoto
{
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
  
  UIImage *image = [UIImage imageWithContentsOfFile:[documentsDirectory stringByAppendingPathComponent:@"app-photo.png"]];
  return image;
}

- (NSURL *) apiURL
{
  return [NYPLConfiguration registrationURL];
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

- (void)updateAccount
{
  [self.sharedAccount setBarcode:self.barcode PIN:[NSString stringWithFormat:@"%ld", (long)self.pin]];
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
  self.applicationUploadTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
    if (error || [(NSHTTPURLResponse *)response statusCode] != 200) {
      self.applicationUploadState = NYPLAssetUploadStateError;
    } else {
      
      // Handle the response
      NSDictionary *responseHeaders = [(NSHTTPURLResponse *)response allHeaderFields];
      NSString *contentTypes = [responseHeaders objectForKey:@"Content-Type"];
      BOOL isJson = NO;
      if (contentTypes)
        isJson = [contentTypes rangeOfString:@"application/json"].location != NSNotFound;
      if (isJson) {
        NSError *jsonReadingError = nil;
        NSDictionary *responseBody = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonReadingError];
        if (jsonReadingError) {
          // Again, this would be pretty serious. Probably we should set an error string or something...
          self.applicationUploadState = NYPLAssetUploadStateError;
        } else {
          self.barcode = [responseBody objectForKey:@"barcode"];
          self.patron_id = [responseBody objectForKey:@"patron_id"];
          self.pin = [[responseBody objectForKey:@"pin"] integerValue];
          self.ptype = [[responseBody objectForKey:@"ptype"] integerValue];
          self.transaction_id = [[responseBody objectForKey:@"id"] integerValue];
          
          [self performSelectorOnMainThread:@selector(updateAccount) withObject:nil waitUntilDone:NO];
        }
      } else {
        // This would actually be a pretty serious error, so it maybe should be handled in a slightly different way
        self.applicationUploadState = NYPLAssetUploadStateError;
      }
      
      self.applicationUploadState = NYPLAssetUploadStateComplete;
    }
  }];
  [self.applicationUploadTask resume];
}

- (void)cancelApplicationUpload
{
  [self.applicationUploadTask cancel];
  self.applicationUploadState = NYPLAssetUploadStateUnknown;
}

@end
