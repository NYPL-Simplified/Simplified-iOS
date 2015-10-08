//
//  NYPLDateCardController.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/5/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLDateCardController.h"
#import "NYPLCardApplicationModel.h"

#define AGE_OF_CONSENT  14

@interface NYPLDateCardController ()
@property (nonatomic, strong) IBOutlet UIDatePicker *datePicker;
@property (nonatomic, strong) IBOutlet UIButton *continueButton;

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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)datePicked:(__attribute__((unused)) id)sender
{
  self.continueButton.enabled = YES;
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
    self.currentApplication.error = NYPLCardApplicationErrorTooYoung;
    __weak NYPLCardApplicationViewController *weakSelf = self;
    self.viewDidAppearCallback = ^() {
      weakSelf.viewDidAppearCallback = nil;
      [weakSelf dismissViewControllerAnimated:YES completion:nil];
    };
    [self performSegueWithIdentifier:@"error" sender:self];
  }
}

#pragma mark - Navigation

/*
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(__attribute__((unused)) id)sender {
}
*/

@end
