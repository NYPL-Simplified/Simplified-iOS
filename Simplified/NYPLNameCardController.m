//
//  NYPLNameCardController.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/6/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLNameCardController.h"
#import "NYPLValidatingTextField.h"

@interface NYPLNameCardController ()
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, weak) NYPLValidatingTextField *currentTextField;
@property (nonatomic, assign) CGFloat keyboardHeight;
@end

@implementation NYPLNameCardController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognized)];
  self.tapGestureRecognizer.numberOfTapsRequired = 1;
  [self.view addGestureRecognizer:self.tapGestureRecognizer];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide) name:UIKeyboardWillHideNotification object:nil];
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)continueButtonPressed:(__attribute__((unused)) id)sender
{
  NSUInteger firstNameLen = [[self.firstNameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length];
  NSUInteger lastNameLen = [[self.lastNameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length];
  
  [self.firstNameField validateWithBlock:^BOOL{
    return firstNameLen != 0;
  }];
  [self.lastNameField validateWithBlock:^BOOL{
    return lastNameLen != 0;
  }];
  
  if (self.lastNameField.valid && self.firstNameField.valid) {
//    [self performSegueWithIdentifier:@"address" sender:nil];
  }
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
  [UIView animateWithDuration:0.25 animations:^{
    self.view.frame = frame;
  }];
}

- (void)keyboardWillHide
{
  CGRect frame = self.view.frame;
  frame.origin.y = 0;
  [UIView animateWithDuration:0.25 animations:^{
    self.view.frame = frame;
  }];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(__attribute__((unused)) UITextField *)textField {
  if (textField == self.firstNameField)
    [self.lastNameField becomeFirstResponder];
  else if (textField == self.lastNameField) {
    [self.lastNameField resignFirstResponder];
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
  [textField resignFirstResponder];
  self.currentTextField = nil;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(__attribute__((unused)) NSRange)range replacementString:(__attribute__((unused)) NSString *)string
{
  [(NYPLValidatingTextField *) textField setValid:YES];
  return YES;
}

@end
