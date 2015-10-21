//
//  NYPLVerifyCardController.h
//  Simplified
//
//  Created by Sam Tarakajian on 10/7/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLCardApplicationViewController.h"
@class NYPLAnimatingButton;

@interface NYPLVerifyCardController : NYPLCardApplicationViewController
@property (nonatomic, strong) IBOutlet NYPLAnimatingButton *submitApplicationButton;
@property (nonatomic, strong) IBOutlet UILabel *nameLabel, *addressLabel, *dobLabel, *emailLabel;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UIView *verifyView;

- (IBAction)submitApplication:(id)sender;
@end
