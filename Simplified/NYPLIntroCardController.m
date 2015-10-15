//
//  NYPLIntroCardController.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/15/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLIntroCardController.h"

@interface NYPLIntroCardController ()

@end

@implementation NYPLIntroCardController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.title = NSLocalizedString(@"Apply", nil);
}

@end
