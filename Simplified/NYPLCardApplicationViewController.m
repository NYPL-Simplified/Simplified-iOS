//
//  NYPLCardApplicationViewController.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/6/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLCardApplicationViewController.h"
#import "NYPLCardApplicationModel.h"
#import "NYPLSettings.h"

@implementation NYPLCardApplicationViewController

- (id) initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    self.navigationItem.title = self.title;
  }
  return self;
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  if (!self.currentApplication)
    self.currentApplication = [NYPLCardApplicationModel currentCardApplication];
  
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

- (void) performSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
  [[NYPLSettings sharedSettings] setCurrentCardApplication:self.currentApplication];
  [super performSegueWithIdentifier:identifier sender:sender];
}

@end
