//
//  NYPLUserAccountFrontEndValidation.h
//  SimplyE
//
//  Created by Ettore Pasquini on 4/14/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

@import UIKit;

@class Account;

/**
 Protocol that represents the input sources / UI requirements for performing
 front-end validation.
 */
@protocol NYPLUserAccountInputProvider
@property(nonatomic) UITextField *usernameTextField;
@property(nonatomic) UITextField *PINTextField;
@end

/**
 Performs front-end validation of user input in the context of user account
 sign-in. It acts as the @p UITextFieldDelegate, so the UI elements defined in
 @p NYPLUserAccountInputProvider should define this class as their @p delegate.
 */
@interface NYPLUserAccountFrontEndValidation : NSObject <UITextFieldDelegate>

/**
 The designated initializer.
 @param account The library account to use for performing validation.
 @param inputProvider The object providing the input fields from which to
 perform validation.
 */
- (instancetype)initWithAccount:(Account*)account
                  inputProvider:(id<NYPLUserAccountInputProvider>)inputProvider;

@end
