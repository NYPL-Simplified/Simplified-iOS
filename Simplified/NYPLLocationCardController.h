//
//  NYPLLocationCardController.h
//  Simplified
//
//  Created by Sam Tarakajian on 10/5/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NYPLCardApplicationViewController.h"

@interface NYPLLocationCardController : NYPLCardApplicationViewController
@property (nonatomic, strong) IBOutlet UIButton *continueButton;
-(IBAction)continueToPhoto:(id)sender;
@end
