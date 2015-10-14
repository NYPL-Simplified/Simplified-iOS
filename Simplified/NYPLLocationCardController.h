//
//  NYPLLocationCardController.h
//  Simplified
//
//  Created by Sam Tarakajian on 10/5/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NYPLCardApplicationViewController.h"

@class NYPLAnimatingButton;

@interface NYPLLocationCardController : NYPLCardApplicationViewController
@property (nonatomic, strong) IBOutlet NYPLAnimatingButton *continueButton;
@property (nonatomic, strong) IBOutlet NYPLAnimatingButton *checkButton;

-(IBAction)checkLocation:(id)sender;
-(IBAction)continueToPhoto:(id)sender;
@end
