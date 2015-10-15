//
//  NYPLDateCardController.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/5/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLDateCardController.h"
#import "NYPLCardApplicationModel.h"
#import "NYPLAnimatingButton.h"

#define AGE_OF_CONSENT  14

@interface NYPLDateCardController ()
@property (nonatomic, strong) IBOutlet UIDatePicker *datePicker;
@property (nonatomic, strong) IBOutlet NYPLAnimatingButton *continueButton;

- (IBAction)datePicked:(id)sender;
@end

@implementation NYPLDateCardController
@synthesize currentApplication;

- (void)viewDidLoad {
  [super viewDidLoad];
  
  if (!self.currentApplication) {
    self.currentApplication = [[NYPLCardApplicationModel alloc] init];
  }
  
  self.continueButton.enabled = NO;
  self.datePicker.date = [NSDate date];
  self.datePicker.maximumDate = [NSDate date];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.title = NSLocalizedString(@"Birthdate", nil);
}

- (IBAction)datePicked:(__attribute__((unused)) id)sender
{
  if (!self.continueButton.enabled) {
    [self.continueButton setEnabled:YES animated:YES];
  }
  self.currentApplication.dob = self.datePicker.date;
}

- (IBAction)continuePressed:(__attribute__((unused)) id)sender
{
  NSCalendar *sysCalendar = [NSCalendar currentCalendar];
  NSDateComponents *components = [sysCalendar components:NSCalendarUnitYear fromDate:self.datePicker.date toDate:[NSDate date] options:NSCalendarMatchFirst];
  NSInteger yearAge = components.year;
  
  if (yearAge >= AGE_OF_CONSENT) {
    [self performSegueWithIdentifier:@"location" sender:self];
  } else {
    UIAlertController *alertViewController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Age Requirement", nil)
                                                                                 message:NSLocalizedString(@"To apply for a library card, please visit an NYPL branch with a parent or guardian", nil)
                                                                          preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alertViewController animated:YES completion:nil];
  }
}

#pragma mark - Navigation

/*
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(__attribute__((unused)) id)sender {
}
*/

@end
