//
//  NYPLProblemReportViewController.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/29/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "NYPLProblemReportViewController.h"

static NSArray *s_problems = nil;

@interface NYPLProblemReportViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) IBOutlet UITableView *problemDescriptionTable;
@property (nonatomic, strong) UIBarButtonItem *submitProblemButton, *cancelButton;
@end

@implementation NYPLProblemReportViewController

+ (void)initialize
{
  s_problems = @[
                 @{
                   @"type": @"http://librarysimplified.org/terms/problem/wrong-genre",
                   @"title": @"Wrong Genre"
                   },
                 @{
                   @"type": @"http://librarysimplified.org/terms/problem/wrong-audience",
                   @"title": @"Wrong Audience"
                   },
                 @{
                   @"type": @"http://librarysimplified.org/terms/problem/wrong-age-range",
                   @"title": @"Wrong Age Range"
                   },
                 @{
                   @"type": @"http://librarysimplified.org/terms/problem/wrong-title",
                   @"title": @"Wrong Title"
                   },
                 @{
                   @"type": @"http://librarysimplified.org/terms/problem/wrong-medium",
                   @"title": @"Wrong Medium"
                   },
                 @{
                   @"type": @"http://librarysimplified.org/terms/problem/wrong-author",
                   @"title": @"Wrong Author"
                   },
                 @{
                   @"type": @"http://librarysimplified.org/terms/problem/bad-cover-image",
                   @"title": @"Wrong/Missing Cover Image"
                   },
                 @{
                   @"type": @"http://librarysimplified.org/terms/problem/bad-description",
                   @"title": @"Wrong/Mismatched Description"
                   },
                 @{
                   @"type": @"http://librarysimplified.org/terms/problem/cannot-fulfill-loan",
                   @"title": @"Can't Download"
                   },
                 @{
                   @"type": @"http://librarysimplified.org/terms/problem/cannot-issue-loan",
                   @"title": @"Can't Borrow"
                   },
                 @{
                   @"type": @"http://librarysimplified.org/terms/problem/cannot-render",
                   @"title": @"Book Contents Blank or Incorrect"
                   },
                 ];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.submitProblemButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Submit", nil)
                                                              style:UIBarButtonItemStyleDone
                                                             target:self action:@selector(submitProblem)];
  self.submitProblemButton.enabled = NO;
  self.navigationItem.rightBarButtonItem = self.submitProblemButton;
  
  self.cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                                              style:UIBarButtonItemStylePlain
                                                             target:self action:@selector(cancel)];
  self.navigationItem.leftBarButtonItem = self.cancelButton;
  
  [self.problemDescriptionTable setBackgroundColor:[UIColor whiteColor]];
}

//- (void)viewWillAppear:(__unused BOOL)animated
//{
//  if (self.modalPresentationStyle != UIModalPresentationPopover) {
//    self.problemTableTopConstraint.constant = 20;
//  }
//}

- (void)submitProblem
{
  NSIndexPath *ip = [self.problemDescriptionTable indexPathForSelectedRow];
  if (ip)
    [self.delegate problemReportViewController:self didSelectProblemWithType:s_problems[ip.row][@"type"]];
}

- (void)cancel
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(__unused NSInteger)section
{
  return s_problems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ProblemReportCell"];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ProblemReportCell"];
  }
  cell.textLabel.text = s_problems[indexPath.row][@"title"];
  cell.textLabel.font = [UIFont systemFontOfSize:16];
  return cell;
}

- (CGFloat)tableView:(__unused UITableView *)tableView heightForRowAtIndexPath:(__unused NSIndexPath *)indexPath
{
  return 44;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  cell.accessoryType = UITableViewCellAccessoryCheckmark;
  if (!self.submitProblemButton.enabled)
    [self.submitProblemButton setEnabled:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  cell.accessoryType = UITableViewCellAccessoryNone;
}

@end
