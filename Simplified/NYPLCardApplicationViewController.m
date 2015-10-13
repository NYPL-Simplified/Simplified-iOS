//
//  NYPLCardApplicationViewController.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/6/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLCardApplicationViewController.h"
#import "NYPLCardApplicationModel.h"

@implementation NYPLCardApplicationViewController

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  [super prepareForSegue:segue sender:sender];
  ((NYPLCardApplicationViewController *) (segue.destinationViewController)).currentApplication = self.currentApplication;
}

- (void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  if (self.navigationController.viewControllers[0] == self) {
    self.navigationItem.hidesBackButton = NO;
    UIBarButtonItem *_backButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = _backButton;
  }
}

- (void) viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  if (self.viewDidAppearCallback) {
    self.viewDidAppearCallback();
  }
}

- (void)dismiss
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

@end
