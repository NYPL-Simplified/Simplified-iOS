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
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) IBOutlet UILabel *statusLabel, *successLabel, *allSetLabel;
@end

@implementation NYPLSendingCardController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.title = NSLocalizedString(@"Sending", nil);
  self.activityIndicator.hidesWhenStopped = YES;
  [self.activityIndicator startAnimating];
  
  self.successLabel.alpha = 0.0;
  self.allSetLabel.alpha = 0.0;
  self.returnToCatalogButton.alpha = 0.0;
  self.returnToCatalogButton.enabled = NO;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [self.currentApplication addObserver:self forKeyPath:@"applicationUploadState" options:0 context:s_applicationUploadContext];
  [self.currentApplication addObserver:self forKeyPath:@"photoUploadState" options:0 context:s_photoUploadContext];
  
  if (!(self.currentApplication.applicationUploadState == NYPLAssetUploadStateComplete)) {
    if (self.currentApplication.photoUploadState == NYPLAssetUploadStateComplete) {
      [self.currentApplication uploadApplication];
    } else if (self.currentApplication.photoUploadState == NYPLAssetUploadStateError) {
      [self showUploadErrorAlert];
    }
    
    [self.currentApplication uploadApplication];
    
  } else {
    [self showSuccess];
  }
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  
  [self.currentApplication removeObserver:self forKeyPath:@"applicationUploadState"];
  [self.currentApplication removeObserver:self forKeyPath:@"photoUploadState"];
}

- (void)showUploadErrorAlert
{
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Upload Failed", nil)
                                                                           message:NSLocalizedString(@"There was an error uploading your library card application. Please try again later", nil)
                                                                    preferredStyle:UIAlertControllerStyleAlert];
  [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Okay", nil)
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(__attribute__((unused))UIAlertAction * _Nonnull action) {
                                                     [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                                                   }]];
  [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showSuccess
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.activityIndicator stopAnimating];
    
    [UIView animateWithDuration:0.3
                     animations:^{
                       self.successLabel.alpha = 1.0;
                       self.allSetLabel.alpha = 1.0;
                       self.returnToCatalogButton.alpha = 1.0;
                       self.statusLabel.alpha = 0.0;
                     }];
    [self.returnToCatalogButton setEnabled:YES animated:YES];
  });
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

- (IBAction)returnToCatalog:(__attribute__((unused))id)sender
{
  [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
