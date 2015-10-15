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
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *selectButtonHeightConstraint, *takeButtonHeightConstraint;
@end

@implementation NYPLPhotoCardController

- (void)viewDidLoad
{
  if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    self.takePhotoButton.enabled = NO;
  if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] &&
      ![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum])
    self.selectPhotoButton.enabled = NO;
  if (self.currentApplication.photo)
    self.imageView.image = self.currentApplication.photo;
  self.continueButton.enabled = (self.currentApplication.photo != nil);
  self.continueButton.alpha = (self.currentApplication.photo != nil) ? 1.0 : 0.0;
  self.selectButtonHeightConstraint.constant = (self.currentApplication.photo != nil) ? -(self.continueButton.frame.size.height + 8.0) : 0;
  self.takeButtonHeightConstraint.constant = (self.currentApplication.photo != nil) ? -(self.continueButton.frame.size.height + 8.0) : 0;
  
  self.title = NSLocalizedString(@"Photo ID", nil);
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
  // If somehow you're on an iDevice with no photo capability whatsoever...
  if (self.selectPhotoButton.enabled == NO && self.takePhotoButton.enabled == NO) {
    
    UIAlertController *alertViewController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"No Camera", nil)
                                                                                 message:NSLocalizedString(@"There is no way to access photos on your device. Please visit an NYPL branch to apply for a library card", nil)
                                                                          preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alertViewController animated:YES completion:nil];
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
  if (chosenImage)
    self.currentApplication.photo = chosenImage;
  void (^completion)(void) = self.currentApplication.photo == nil ? nil : ^() {
    [self.view layoutIfNeeded];
    self.selectButtonHeightConstraint.constant = -(self.continueButton.frame.size.height + 8.0);
    self.takeButtonHeightConstraint.constant = -(self.continueButton.frame.size.height + 8.0);
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                       self.continueButton.alpha = 1.0;
                     } completion:nil];
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                       [self.view layoutIfNeeded];
                     } completion:nil];
    [UIView transitionWithView:self.imageView
                      duration:0.5
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                      self.imageView.image = self.currentApplication.photo;
                    } completion:nil];
    [self.continueButton setEnabled:YES animated:YES];
  };
  [picker dismissViewControllerAnimated:YES completion:completion];
  [self.currentApplication uploadPhoto];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
  [picker dismissViewControllerAnimated:YES completion:NULL];
}

@end
