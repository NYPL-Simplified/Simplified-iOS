//
//  NYPLNameCardController.m
//  Simplified
//
//  Created by Sam Tarakajian on 10/6/15.
//  Copyright © 2015 NYPL Labs. All rights reserved.
//

#import "NYPLNameCardController.h"
#import "NYPLValidatingTextField.h"
#import "NYPLAnimatingButton.h"
#import "NYPLCardApplicationModel.h"

@interface NYPLNameCardController () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, weak) NYPLValidatingTextField *currentTextField;
@property (nonatomic, assign) CGFloat keyboardHeight;
@property (nonatomic, assign) BOOL segueOnKeyboardHide;
@end

@implementation NYPLNameCardController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognized)];
  self.tapGestureRecognizer.numberOfTapsRequired = 1;
  self.tapGestureRecognizer.delegate = self;
  [self.view addGestureRecognizer:self.tapGestureRecognizer];
  
  self.firstNameField.validator = ^BOOL() {
    return [[self.firstNameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0;
  };
  self.lastNameField.validator = ^BOOL() {
    return [[self.lastNameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0;
  };
}

- (void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self.firstNameField setText:self.currentApplication.firstName];
  [self.lastNameField setText:self.currentApplication.lastName];
  self.imageView.image = self.currentApplication.photo;
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
  
  self.title = NSLocalizedString(@"Name", nil);
}

- (void) viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)continueButtonPressed:(id)sender
{
  [self.firstNameField validate];
  [self.lastNameField validate];
  
  if (self.lastNameField.valid && self.firstNameField.valid) {
    if (self.firstNameField.isFirstResponder || self.lastNameField.isFirstResponder) {
      [self.firstNameField resignFirstResponder];
      [self.lastNameField resignFirstResponder];
      self.segueOnKeyboardHide = YES;
    } else {
      [self performSegueWithIdentifier:@"address" sender:sender];
    }
  }
}

- (void)tapGestureRecognized
{
  [self.currentTextField resignFirstResponder];
}

- (BOOL)gestureRecognizer:(__attribute__((unused)) UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
  if (touch.view == self.continueButton)
    return NO;
  return YES;
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
      [self performSegueWithIdentifier:@"address" sender:nil];
    }
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
  if (textField == self.firstNameField)
    self.currentApplication.firstName = [self.firstNameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if (textField == self.lastNameField)
    self.currentApplication.lastName = [self.lastNameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  [textField resignFirstResponder];
  self.currentTextField = nil;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(__attribute__((unused)) NSRange)range replacementString:(__attribute__((unused)) NSString *)string
{
  [(NYPLValidatingTextField *) textField setValid:YES];
  return YES;
}

@end
