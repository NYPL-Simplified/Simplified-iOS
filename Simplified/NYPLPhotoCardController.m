//
//  NYPLPhotoCardController.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/6/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLPhotoCardController.h"
#import "NYPLCardApplicationModel.h"

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

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
  UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
  self.currentApplication.photo = chosenImage;
  self.imageView.image = chosenImage;
  [picker dismissViewControllerAnimated:YES completion:NULL];
  NSString *timeString = [NSString stringWithFormat:@"%f", [NSDate timeIntervalSinceReferenceDate]];
  NSString *uniqueName = [NYPLPhotoCardController md5HexDigest:timeString];
  
  NSURL *uploadURL = [self.currentApplication.apiURL URLByAppendingPathComponent:@"upload"];
  NSMutableURLRequest *photoUpload = [NSMutableURLRequest requestWithURL:uploadURL];
  photoUpload.HTTPMethod = @"POST";
  [photoUpload addValue:@"false" forHTTPHeaderField:@"processData"];
  [photoUpload addValue:@"json" forHTTPHeaderField:@"dataType"];
  
  NSData *imageData = UIImageJPEGRepresentation(self.currentApplication.photo, 1);
  
  NSMutableData *body = [NSMutableData data];
  
  NSString *boundary = @"----WebKitFormBoundaryN6A1gqzZKvhX5Fhl";
  NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
  [photoUpload addValue:contentType forHTTPHeaderField:@"Content-Type"];
  
  //The file to upload
  [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[NSData dataWithData:imageData]];
  [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
  
  [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"name\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[[NSString stringWithFormat:@"%@.jpg\r\n", uniqueName] dataUsingEncoding:NSUTF8StringEncoding]];
  
  // close the form
  [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  
  // set request body
  [photoUpload setHTTPBody:body];
  
  // Configure your request here.  Set timeout values, HTTP Verb, etc.
  NSURLConnection *connection = [NSURLConnection connectionWithRequest:photoUpload delegate:self];
  
  //start the connection
  [connection start];
  
//  [self performSegueWithIdentifier:@"name" sender:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
  [picker dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark NSURLConnection delegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
  NSLog(@"Connection failed with error %@", error.localizedDescription);
}

- (nullable NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(nullable NSURLResponse *)response
{
  NSLog(@"About to send request");
  return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
  NSLog(@"Received response");
}

- (void)connection:(NSURLConnection *)connection   didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
  NSLog(@"Sent %ld of %ld bytes", (long)totalBytesWritten, totalBytesExpectedToWrite);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  NSLog(@"Connection finished");
}

@end
