//
//  NYPLUserAccountFrontEndValidation.m
//  SimplyE
//
//  Created by Ettore Pasquini on 4/14/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

#import "SimplyE-Swift.h"
#import "NYPLUserAccountFrontEndValidation.h"


@interface NYPLUserAccountFrontEndValidation ()
@property(weak) id<NYPLUserAccountInputProvider> userInputProvider;
@property Account *account;
@end

@implementation NYPLUserAccountFrontEndValidation

- (instancetype)initWithAccount:(Account*)account
                  inputProvider:(id<NYPLUserAccountInputProvider>)inputProvider
{
  self = [super init];
  if (self) {
    self.userInputProvider = inputProvider;
    self.account = account;
  }

  return self;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(__unused UITextField *)textField
{
  return ![[NYPLUserAccount sharedAccount:self.account.uuid] hasBarcodeAndPIN];
}

- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string
{
  if(![string canBeConvertedToEncoding:NSASCIIStringEncoding]) {
    return NO;
  }

  if (textField == self.userInputProvider.usernameTextField &&
      self.account.details.patronIDKeyboard != LoginKeyboardEmail) {

    // Barcodes are numeric and usernames are alphanumeric including punctuation
    NSMutableCharacterSet *allowedChars = [NSMutableCharacterSet alphanumericCharacterSet];
    [allowedChars formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];

    if ([string stringByTrimmingCharactersInSet:allowedChars].length > 0) {
      return NO;
    }

    // Usernames cannot be longer than 25 characters.
    if (range.location < 0 || range.location + range.length > textField.text.length || [textField.text stringByReplacingCharactersInRange:range withString:string].length > 25) {
      return NO;
    }
  }

  if (textField == self.userInputProvider.PINTextField) {
    NSCharacterSet *charSet = [NSCharacterSet decimalDigitCharacterSet];
    bool alphanumericPin = self.account.details.pinKeyboard != LoginKeyboardNumeric;
    bool containsNonNumericChar = [string stringByTrimmingCharactersInSet:charSet].length > 0;
    bool abovePinCharLimit = [textField.text stringByReplacingCharactersInRange:range withString:string].length > self.account.details.authPasscodeLength;

    // PIN's support numeric or alphanumeric.
    if (!alphanumericPin && containsNonNumericChar) {
      return NO;
    }

    // PIN's character limit. Zero is unlimited.
    if (self.account.details.authPasscodeLength == 0) {
      return YES;
    } else if (abovePinCharLimit) {
      return NO;
    }
  }

  return YES;
}

@end
