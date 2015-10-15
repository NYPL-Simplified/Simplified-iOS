//
//  NYPLSendingCardController.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/7/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLSendingCardController.h"
#import "NYPLCardApplicationModel.h"

@interface NYPLSendingCardController ()

@end

@implementation NYPLSendingCardController

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  if (!self.currentApplication.applicationSent)
    [self.currentApplication uploadApplication];
}

@end
