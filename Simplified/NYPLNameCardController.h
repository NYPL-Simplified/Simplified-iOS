//
//  NYPLNameCardController.h
//  Simplified
//
//  Created by Sam Tarakajian on 10/6/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLCardApplicationViewController.h"
@class NYPLValidatingTextField;
@class NYPLAnimatingButton;

@interface NYPLNameCardController : NYPLCardApplicationViewController <UITextFieldDelegate>
@property (nonatomic, strong) IBOutlet NYPLValidatingTextField *firstNameField, *lastNameField;
@property (nonatomic, strong) IBOutlet NYPLAnimatingButton *continueButton;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;

- (IBAction)continueButtonPressed:(id)sender;
@end
