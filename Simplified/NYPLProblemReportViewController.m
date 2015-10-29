//
//  NYPLProblemReportViewController.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/29/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLProblemReportViewController.h"
#import "NYPLAnimatingButton.h"

static NSArray *s_problems = nil;

@interface NYPLProblemReportViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) IBOutlet UITableView *problemDescriptionTable;
@property (nonatomic, strong) NYPLAnimatingButton *submitProblemButton;
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
  self.problemDescriptionTable.scrollEnabled = NO;
  self.submitProblemButton = [NYPLAnimatingButton buttonWithType:UIButtonTypeSystem];
  [self.submitProblemButton setTitle:NSLocalizedString(@"Submit", nil) forState:UIControlStateNormal];
  [self.submitProblemButton addTarget:self action:@selector(submitProblem) forControlEvents:UIControlEventTouchUpInside];
  self.submitProblemButton.enabled = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  CGFloat maxWidth = 0.0;
  CGFloat height = 0;
  for (uint i=0; i<[self.problemDescriptionTable numberOfRowsInSection:0]; ++i) {
    UILabel *l = [[self.problemDescriptionTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]] textLabel];
    maxWidth = MAX(maxWidth, l.bounds.size.width);
    height += [self.problemDescriptionTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]].bounds.size.height;
  }
  height += 45.0;
  self.preferredContentSize = CGSizeMake(maxWidth+16.0, height+8);
}

- (void)submitProblem
{
  NSIndexPath *ip = [self.problemDescriptionTable indexPathForSelectedRow];
  if (ip)
    [self.delegate problemReportViewController:self didSelectProblemWithType:s_problems[ip.row][@"type"]];
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
  return cell;
}

- (UIView *)tableView:(__unused UITableView *)tableView viewForFooterInSection:(__unused NSInteger)section
{
  return self.submitProblemButton;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  cell.accessoryType = UITableViewCellAccessoryCheckmark;
  if (!self.submitProblemButton.enabled)
    [self.submitProblemButton setEnabled:YES animated:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  cell.accessoryType = UITableViewCellAccessoryNone;
}

- (CGFloat)tableView:(__unused UITableView *)tableView heightForFooterInSection:(__unused NSInteger)section
{
  return 45.0;
}

@end
