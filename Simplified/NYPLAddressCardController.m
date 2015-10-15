//
//  NYPLAddressCardController.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/7/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLAddressCardController.h"
#import "NYPLAnimatingButton.h"
#import "NYPLValidatingTextField.h"
#import "NYPLCardApplicationModel.h"

@interface NYPLAddressCardController () <UIGestureRecognizerDelegate, UITextFieldDelegate>
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, assign) BOOL segueOnKeyboardHide;
@property (nonatomic, weak) NYPLValidatingTextField *currentTextField;
@end

@implementation NYPLAddressCardController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.addressTextField.validator = ^BOOL() {
    return [[self.addressTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 5;
  };
  
  self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognized)];
  self.tapGestureRecognizer.numberOfTapsRequired = 1;
  self.tapGestureRecognizer.delegate = self;
  [self.view addGestureRecognizer:self.tapGestureRecognizer];
}

- (void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
  
  self.title = NSLocalizedString(@"Address", nil);
  self.imageView.image = self.currentApplication.photo;
}

- (void) viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)continueButtonPressed:(id)sender
{
  [self.addressTextField validate];
  
  if (self.addressTextField.valid) {
    if (self.addressTextField.isFirstResponder) {
      [self.addressTextField resignFirstResponder];
      self.segueOnKeyboardHide = YES;
    } else {
      [self performSegueWithIdentifier:@"email" sender:sender];
    }
  }
}

#pragma mark Gestures

- (BOOL)gestureRecognizer:(__attribute__((unused)) UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
  if (touch.view == self.continueButton)
    return NO;
  return YES;
}

- (void)tapGestureRecognized
{
  [self.currentTextField resignFirstResponder];
}

#pragma mark Keyboard Notifications

-(void)keyboardWillShow:(NSNotification* )notification
{
  CGFloat keyboardHeight = ((CGRect) [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue]).size.height;
  CGRect frame = self.view.frame;
  frame.origin.y = -keyboardHeight;
  double duration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
  [UIView animateWithDuration:duration animations:^{
    self.view.frame = frame;
  }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
  CGRect frame = self.view.frame;
  frame.origin.y = 0;
  double duration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
  [UIView animateWithDuration:duration animations:^{
    self.view.frame = frame;
  } completion:^(BOOL finished) {
    if (finished && self.segueOnKeyboardHide) {
      self.segueOnKeyboardHide = NO;
      [self performSegueWithIdentifier:@"email" sender:nil];
    }
  }];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(__attribute__((unused)) UITextField *)textField {
  if (textField == self.addressTextField) {
    [self.addressTextField resignFirstResponder];
    [self continueButtonPressed:self.continueButton];
  }
  
  return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
  self.currentTextField = (NYPLValidatingTextField *) textField;
  self.currentTextField.valid = YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
  if (textField == self.addressTextField)
    self.currentApplication.address = [self.addressTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  [textField resignFirstResponder];
  self.currentTextField = nil;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(__attribute__((unused)) NSRange)range replacementString:(__attribute__((unused)) NSString *)string
{
  [(NYPLValidatingTextField *) textField setValid:YES];
  return YES;
}


@end
