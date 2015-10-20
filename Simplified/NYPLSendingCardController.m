//
//  NYPLSendingCardController.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/7/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLSendingCardController.h"
#import "NYPLCardApplicationModel.h"
#import "NYPLAnimatingButton.h"

static void *s_applicationUploadContext = &s_applicationUploadContext;
static void *s_photoUploadContext = &s_photoUploadContext;

@interface NYPLSendingCardController ()
@property (nonatomic, strong) UIAlertController *submittingController;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) IBOutlet UILabel *successLabel, *allSetLabel;
@property (nonatomic, strong) IBOutlet UIImageView *successCard, *successCheck;
@end

@implementation NYPLSendingCardController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.activityIndicator.hidesWhenStopped = YES;
  [self.activityIndicator startAnimating];
  
  self.verifyView.hidden = NO;
  self.successView.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [self.currentApplication addObserver:self forKeyPath:@"applicationUploadState" options:0 context:s_applicationUploadContext];
  [self.currentApplication addObserver:self forKeyPath:@"photoUploadState" options:0 context:s_photoUploadContext];
  
  self.nameLabel.text = [NSString stringWithFormat:@"%@ %@", self.currentApplication.firstName, self.currentApplication.lastName];
  self.dobLabel.text = [NSDateFormatter localizedStringFromDate:self.currentApplication.dob dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
  self.addressLabel.text = self.currentApplication.address;
  self.emailLabel.text = self.currentApplication.email;
  self.imageView.image = self.currentApplication.photo;
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  
  [self.currentApplication removeObserver:self forKeyPath:@"applicationUploadState"];
  [self.currentApplication removeObserver:self forKeyPath:@"photoUploadState"];
}

- (void)showUploadErrorAlert
{
  [self.submittingController dismissViewControllerAnimated:YES completion:^{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Upload Failed", nil)
                                                                             message:NSLocalizedString(@"There was an error uploading your library card application. Please try again later", nil)
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Okay", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(__attribute__((unused))UIAlertAction * _Nonnull action) {
                                                        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                                                      }]];
    [self presentViewController:alertController animated:YES completion:nil];
  }];
  self.submittingController = nil;
}

- (void)showSuccess
{
  [self.submittingController dismissViewControllerAnimated:YES completion:^{
    [UIView transitionWithView:self.view
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                      self.verifyView.hidden = YES;
                      self.successView.hidden = NO;
                    } completion:^(BOOL finished) {
                      if (finished) {
                        [self.returnToCatalogButton setEnabled:YES animated:YES];
                        self.navigationItem.backBarButtonItem = nil;
                      }
                    }];
  }];
  self.submittingController = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
  if (context == s_applicationUploadContext) {
    if (self.currentApplication.applicationUploadState == NYPLAssetUploadStateComplete) {
      [self showSuccess];
    } else if (self.currentApplication.applicationUploadState == NYPLAssetUploadStateError) {
      [self showUploadErrorAlert];
    }
  } else if (context == s_photoUploadContext) {
    if (self.currentApplication.photoUploadState == NYPLAssetUploadStateComplete) {
      if (self.currentApplication.applicationUploadState != NYPLAssetUploadStateComplete) {
        [self.currentApplication uploadApplication];
      }
    } else if (self.currentApplication.photoUploadState == NYPLAssetUploadStateError) {
      [self showUploadErrorAlert];
    }
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

- (IBAction)submitApplication:(__attribute__((unused)) id)sender
{
  self.submittingController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Submitting", nil)
                                                                  message:NSLocalizedString(@"Submitting your application", nil)
                                                           preferredStyle:UIAlertControllerStyleAlert];
  [self.submittingController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(__attribute__((unused)) UIAlertAction * _Nonnull action) {
                                                           [self.currentApplication cancelApplicationUpload];
                                                         }]];
  
  [self presentViewController:self.submittingController animated:YES completion:^{
    
    if (self.currentApplication.applicationUploadState != NYPLAssetUploadStateComplete) {
      if (self.currentApplication.photoUploadState == NYPLAssetUploadStateComplete) {
        [self.currentApplication uploadApplication];
      } else if (self.currentApplication.photoUploadState == NYPLAssetUploadStateError) {
        [self showUploadErrorAlert];
      }
      
      // If none of these, don't worry: we'll send the application once the photo is done uploading
    }
    
    else {
      [self showSuccess];
    }
  }];
}

- (IBAction)returnToCatalog:(__attribute__((unused))id)sender
{
  [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
