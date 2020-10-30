//
//  NYPLSignInURLSessionChallengeHandler.h
//  SimplyE
//
//  Created by Ettore Pasquini on 2/21/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

// TODO: SIMPLY-2510 perhaps consolidate with NYPLSignInBusinessLogicUIDelegate
/**
 Defines the interface required by the URLSession delegate to perform the
 authentication challenge.
 */
@protocol NYPLSettingsAccountUIDelegate <NSObject>
@required
- (nullable NSString *)username;
- (nullable NSString *)pin;
@end

/**
 A class responsible for handling the authentication challenge initiated
 during the sign-in process.
 */
@interface NYPLSignInURLSessionChallengeHandler : NSObject <NSURLSessionDelegate>

@property(nullable, weak) id<NYPLSettingsAccountUIDelegate> uiDelegate;

- (nonnull instancetype)initWithUIDelegate:(nullable id<NYPLSettingsAccountUIDelegate>)uiDelegate;

@end
