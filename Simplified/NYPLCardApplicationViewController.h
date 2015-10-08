//
//  NYPLCardApplicationViewController.h
//  Simplified
//
//  Created by Sam Tarakajian on 10/6/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NYPLCardApplicationModel;

@interface NYPLCardApplicationViewController : UIViewController
@property (nonatomic, strong) NYPLCardApplicationModel *currentApplication;
@property (nonatomic, copy) void (^viewDidAppearCallback)(void);
@end
