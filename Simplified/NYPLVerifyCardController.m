//
//  NYPLVerifyCardController.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/7/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLVerifyCardController.h"
#import "NYPLCardApplicationModel.h"
#import "NYPLAnimatingButton.h"
#import "NYPLSubmittingViewController.h"

@interface NYPLVerifyCardController () <NYPLSubmittingViewControllerDelegate>
@property (nonatomic, strong) NYPLCardApplicationViewController *submittingController;
@end

@implementation NYPLVerifyCardController

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  self.nameLabel.text = [NSString stringWithFormat:@"%@ %@", self.currentApplication.firstName, self.currentApplication.lastName];
  self.dobLabel.text = [NSDateFormatter localizedStringFromDate:self.currentApplication.dob dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
  self.addressLabel.text = self.currentApplication.address;
  self.emailLabel.text = self.currentApplication.email;
  self.imageView.image = self.currentApplication.photo;
}

- (IBAction)submitApplication:(__attribute__((unused)) id)sender
{
  [self performSegueWithIdentifier:@"submit" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(__attribute__((unused)) id)sender
{
  if ([segue.destinationViewController isKindOfClass:[NYPLSubmittingViewController class]]) {
    NYPLSubmittingViewController *sbv = segue.destinationViewController;
    sbv.delegate = self;
  }
}

#pragma mark NYPLSubmittingViewControllerDelegate

- (void)submittingViewControllerDidReturnToCatalog:(NYPLSubmittingViewController *)vc
{
  [vc dismissViewControllerAnimated:NO completion:^{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
  }];
}

- (void)submittingViewControllerDidCancel:(NYPLSubmittingViewController *)vc
{
  [vc dismissViewControllerAnimated:YES completion:nil];
}

@end
