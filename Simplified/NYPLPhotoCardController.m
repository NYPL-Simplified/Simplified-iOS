//
//  NYPLPhotoCardController.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/6/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLPhotoCardController.h"
#import "NYPLCardApplicationModel.h"
#import "NYPLAnimatingButton.h"

#import <CommonCrypto/CommonDigest.h>

@interface NYPLPhotoCardController () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
@end

@implementation NYPLPhotoCardController

+ (NSString*)md5HexDigest:(NSString*)input {
  const char* str = [input UTF8String];
  unsigned char result[CC_MD5_DIGEST_LENGTH];
  CC_MD5(str, (CC_LONG) strlen(str), result);
  
  NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];
  for(int i = 0; i<CC_MD5_DIGEST_LENGTH; i++) {
    [ret appendFormat:@"%02x",result[i]];
  }
  return ret;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    self.takePhotoButton.enabled = NO;
  if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] &&
      ![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum])
    self.selectPhotoButton.enabled = NO;
  self.continueButton.enabled = (self.currentApplication.photo != nil);
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
  // If somehow you're on an iDevice with no photo capability whatsoever...
  if (self.selectPhotoButton.enabled == NO && self.takePhotoButton.enabled == NO) {
    self.currentApplication.error = NYPLCardApplicationErrorNoCamera;
    
    __weak NYPLPhotoCardController *weakSelf = self;
    self.viewDidAppearCallback = ^() {
      [weakSelf dismissViewControllerAnimated:YES completion:nil];
    };
    [self performSegueWithIdentifier:@"error" sender:nil];
  }
}

- (IBAction)selectPhoto:(__attribute__((unused)) id)sender
{
  UIImagePickerController *picker = [[UIImagePickerController alloc] init];
  picker.delegate = self;
  picker.allowsEditing = YES;
  picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  
  [self presentViewController:picker animated:YES completion:NULL];
}

- (IBAction)takePhoto:(__attribute__((unused)) id)sender
{
  UIImagePickerController *picker = [[UIImagePickerController alloc] init];
  picker.delegate = self;
  picker.allowsEditing = YES;
  picker.sourceType = UIImagePickerControllerSourceTypeCamera;
  
  [self presentViewController:picker animated:YES completion:NULL];
}

- (IBAction)continuePressed:(id)sender
{
  [self performSegueWithIdentifier:@"name" sender:sender];
}

#pragma mark UIImagePickerControllerDelegate

- (void)uploadStuff {
  // from: http://stackoverflow.com/a/8567771/160933
  
  NSString *timeString = [NSString stringWithFormat:@"%f", [NSDate timeIntervalSinceReferenceDate]];
  NSString *uniqueName = [NSString stringWithFormat:@"ios-%@.jpg", [NYPLPhotoCardController md5HexDigest:timeString]];
  self.currentApplication.awsPhotoName = uniqueName;
  
  // Dictionary that holds post parameters. You can set your post parameters that your server accepts or programmed to accept.
  NSMutableDictionary* _params = [[NSMutableDictionary alloc] init];
  [_params setObject:uniqueName forKey:@"name"];
  NSLog(@"Unique name: %@", uniqueName);
  
  // the boundary string : a random string, that will not repeat in post data, to separate post data fields.
  NSString *BoundaryConstant = @"----------V2ymHFg03ehbqgZCaKO6jy";
  
  // string constant for the post parameter 'file'. My server uses this name: `file`. Your's may differ
  NSString* FileParamConstant = @"file";
  
  // the server url to which the image (or the media) is uploaded. Use your server url here
  NSURL *requestURL = [self.currentApplication.apiURL URLByAppendingPathComponent:@"upload"];
  
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
  NSData *imageData = UIImageJPEGRepresentation(self.currentApplication.photo, 0.7);
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
  NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
    NSLog(@"Uploaded!");
  }];
  [task resume];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
  UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
  self.currentApplication.photo = chosenImage;
  [picker dismissViewControllerAnimated:YES completion:^{
    [UIView transitionWithView:self.imageView
                      duration:0.5
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                      self.imageView.image = chosenImage;
                    } completion:^(BOOL finished) {
                      if (finished) {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                          [self.continueButton setEnabled:YES animated:YES];
                        });
                      }
                    }];
  }];

  [self uploadStuff];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
  [picker dismissViewControllerAnimated:YES completion:NULL];
}

@end
