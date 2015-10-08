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

- (void) viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  if (self.viewDidAppearCallback) {
    self.viewDidAppearCallback();
  }
}

@end
