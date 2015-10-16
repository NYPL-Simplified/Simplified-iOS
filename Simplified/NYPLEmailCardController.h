//
//  NYPLEmailCardController.h
//  Simplified
//
//  Created by Sam Tarakajian on 10/7/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLCardApplicationViewController.h"
@class NYPLAnimatingButton;
@class NYPLValidatingTextField;

@interface NYPLEmailCardController : NYPLCardApplicationViewController
@property (nonatomic, strong) IBOutlet NYPLAnimatingButton *continueButton;
@property (nonatomic, strong) IBOutlet NYPLValidatingTextField *emailTextField;
- (IBAction)continueButtonPressed:(id)sender;
@end
