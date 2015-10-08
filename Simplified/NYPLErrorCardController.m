//
//  NYPLErrorCardController.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/5/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLErrorCardController.h"
#import "NYPLCardApplicationModel.h"

@interface NYPLErrorCardController ()

@end

@implementation NYPLErrorCardController

- (void)configureErrorDisplayForCurrentState
{
  NYPLCardApplicationError e = self.currentApplication.error; // noerr if no application
  
  switch (e) {
    case NYPLCardApplicationNoError:
      self.errorLabel.text = NSLocalizedString(@"How did you get here? This should be impossible", nil);
      break;
    case NYPLCardApplicationErrorTooYoung:
      self.errorLabel.text = NSLocalizedString(@"To apply for a library card, please visit the library with a parent or guardian", nil);
      break;
    case NYPLCardApplicationErrorNoLocation:
      self.errorLabel.text = NSLocalizedString(@"We couldn't determine your location, but that's okay! You just won't be able to check out books until you get your card", nil);
      break;
    case NYPLCardApplicationErrorNotInNY:
      self.errorLabel.text = NSLocalizedString(@"It looks like you're not in NY State. If you're a resident, you can continue, but you won't be able to check out books until you get your card", nil);
      break;
    case NYPLCardApplicationErrorNoCamera:
      self.errorLabel.text = NSLocalizedString(@"You don't seem to have a way to upload an image. Please visit the library to apply in person", nil);
      break;
      
    default:
      self.errorLabel.text = NSLocalizedString(@"How did you get here? This should be impossible", nil);
      break;
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self configureErrorDisplayForCurrentState];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)okayPressed:(__attribute__((unused)) id)sender
{
  switch (self.currentApplication.error) {
    case NYPLCardApplicationNoError:
      [self dismissViewControllerAnimated:YES completion:nil];
      break;
    case NYPLCardApplicationErrorTooYoung:
      [self dismissViewControllerAnimated:YES completion:nil];
      break;
    case NYPLCardApplicationErrorNotInNY:
      [self dismissViewControllerAnimated:YES completion:nil];
      break;
    case NYPLCardApplicationErrorNoLocation:
      [self dismissViewControllerAnimated:YES completion:nil];
      break;
    case NYPLCardApplicationErrorNoCamera:
      [self dismissViewControllerAnimated:YES completion:nil];
      break;
  }
  
}

- (void)setCurrentApplication:(NYPLCardApplicationModel *)currentApplication
{
  [super setCurrentApplication:currentApplication];
  [self configureErrorDisplayForCurrentState];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
