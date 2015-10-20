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
#import "NYPLSettings.h"

#define AGE_OF_CONSENT  14

@interface NYPLDateCardController ()
@property (nonatomic, strong) IBOutlet UIDatePicker *datePicker;
@property (nonatomic, strong) IBOutlet NYPLAnimatingButton *continueButton;

- (IBAction)datePicked:(id)sender;
@end

@implementation NYPLDateCardController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.datePicker.maximumDate = [NSDate date];
  
  if (self.currentApplication.dob) {
    self.continueButton.enabled = YES;
    self.datePicker.date = self.currentApplication.dob;
  } else {
    self.continueButton.enabled = NO;
    self.datePicker.date = [NSDate date];
  }
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
    [alertViewController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Okay", nil)
                                                            style:UIAlertActionStyleCancel
                                                          handler:nil]];
    [self presentViewController:alertViewController animated:YES completion:nil];
  }
}

@end
