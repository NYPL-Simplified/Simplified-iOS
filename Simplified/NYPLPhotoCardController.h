//
//  NYPLPhotoCardController.h
//  Simplified
//
//  Created by Sam Tarakajian on 10/6/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLCardApplicationViewController.h"

@class NYPLAnimatingButton;

@interface NYPLPhotoCardController : NYPLCardApplicationViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) IBOutlet NYPLAnimatingButton *selectPhotoButton, *takePhotoButton, *continueButton;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
- (IBAction)selectPhoto:(id)sender;
- (IBAction)takePhoto:(id)sender;
- (IBAction)continuePressed:(id)sender;
@end
