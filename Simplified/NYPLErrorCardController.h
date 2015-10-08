//
//  NYPLErrorCardController.h
//  Simplified
//
//  Created by Sam Tarakajian on 10/5/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NYPLCardApplicationViewController.h"

@interface NYPLErrorCardController : NYPLCardApplicationViewController

@property (nonatomic, strong) IBOutlet UILabel *errorLabel;

- (IBAction)okayPressed:(id)sender;

@end
