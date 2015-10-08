//
//  NYPLPhotoCardController.h
//  Simplified
//
//  Created by Sam Tarakajian on 10/6/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLCardApplicationViewController.h"

@interface NYPLPhotoCardController : NYPLCardApplicationViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) IBOutlet UIButton *selectPhotoButton, *takePhotoButton;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
- (IBAction)selectPhoto:(id)sender;
- (IBAction)takePhoto:(id)sender;
@end
