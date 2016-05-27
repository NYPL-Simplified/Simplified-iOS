//
//  NYPLSubmittingViewController.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/21/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLSubmittingViewController.h"
#import "NYPLCardApplicationModel.h"
#import "NYPLAnimatingButton.h"

static void *s_applicationUploadContext = &s_applicationUploadContext;
static void *s_photoUploadContext = &s_photoUploadContext;

@interface NYPLSubmittingViewController ()
@property (nonatomic, strong) IBOutlet NYPLAnimatingButton *cancelButton, *returnToCatalogButton;
@property (nonatomic, strong) IBOutlet UIView *successContainer, *sendingContainer;
@property (nonatomic, strong) IBOutlet UILabel *successLabel, *allSetLabel;
@property (nonatomic, strong) IBOutlet UIImageView *successCard, *successCheck;
@end

@implementation NYPLSubmittingViewController

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  self.cancelButton.enabled = YES;
  [self.currentApplication addObserver:self forKeyPath:@"applicationUploadState" options:0 context:s_applicationUploadContext];
  [self.currentApplication addObserver:self forKeyPath:@"photoUploadState" options:0 context:s_photoUploadContext];
  
  if (self.currentApplication.applicationUploadState == NYPLAssetUploadStateComplete) {
    [NYPLCardApplicationModel clearCurrentApplication];
    self.sendingContainer.hidden = YES;
    self.successContainer.hidden = NO;
    [self.returnToCatalogButton setEnabled:YES];
  } else {
    if (self.currentApplication.photoUploadState == NYPLAssetUploadStateError) {
      [self showUploadErrorAlert];
    } else if (self.currentApplication.photoUploadState == NYPLAssetUploadStateComplete) {
      [self.currentApplication uploadApplication];
    }
    
    // Otherwise, we'll send the application once the photo is done uploading
  }
}


- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  
  [self.currentApplication removeObserver:self forKeyPath:@"applicationUploadState"];
  [self.currentApplication removeObserver:self forKeyPath:@"photoUploadState"];
}

- (IBAction)returnToCatalog:(__attribute__((unused)) id)sender
{
  [self.delegate submittingViewControllerDidReturnToCatalog:self];
}

- (IBAction)cancel:(__attribute__((unused)) id)sender
{
  [self.currentApplication cancelApplicationUpload];
  [self.delegate submittingViewControllerDidCancel:self];
}

#pragma mark Upload

- (void)showUploadErrorAlert
{
  self.cancelButton.enabled = NO;
  [self.cancelButton cancelTrackingWithEvent:nil];
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Upload Failed", nil)
                                                                           message:NSLocalizedString(@"There was an error uploading your library card application. Please try again later", nil)
                                                                    preferredStyle:UIAlertControllerStyleAlert];
  [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Okay", nil)
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(__attribute__((unused))UIAlertAction * _Nonnull action) {
                                                      [self dismissViewControllerAnimated:YES completion:nil];
                                                    }]];
  [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showSuccess
{
  self.cancelButton.enabled = NO;
  [self.cancelButton cancelTrackingWithEvent:nil];
  [UIView transitionWithView:self.view
                    duration:0.5
                     options:UIViewAnimationOptionTransitionCrossDissolve
                  animations:^{
                    self.sendingContainer.hidden = YES;
                    self.successContainer.hidden = NO;
                  } completion:^(BOOL finished) {
                    if (finished) {
                      [self.returnToCatalogButton setEnabled:YES];
                    }
                  }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
  if (context == s_applicationUploadContext) {
    if (self.currentApplication.applicationUploadState == NYPLAssetUploadStateComplete) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [NYPLCardApplicationModel clearCurrentApplication];
        [self showSuccess];
      });
    } else if (self.currentApplication.applicationUploadState == NYPLAssetUploadStateError) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self showUploadErrorAlert];
      });
    }
  } else if (context == s_photoUploadContext) {
    if (self.currentApplication.photoUploadState == NYPLAssetUploadStateComplete) {
      if (self.currentApplication.applicationUploadState != NYPLAssetUploadStateComplete) {
        [self.currentApplication uploadApplication];
      }
    } else if (self.currentApplication.photoUploadState == NYPLAssetUploadStateError) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self showUploadErrorAlert];
      });
    }
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

@end
