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

@interface NYPLPhotoCardController () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
@end

@implementation NYPLPhotoCardController

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    self.takePhotoButton.enabled = NO;
  if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] &&
      ![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum])
    self.selectPhotoButton.enabled = NO;
  self.continueButton.enabled = (self.currentApplication.photo != nil);
  
  self.title = NSLocalizedString(@"Upload Identification", nil);
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

  [self.currentApplication uploadPhoto];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
  [picker dismissViewControllerAnimated:YES completion:NULL];
}

@end
