//
//  NYPLSettingsAccountURLSessionChallengeHandler.h
//  SimplyE
//
//  Created by Ettore Pasquini on 2/21/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Defines the interface required by the URLSession delegate to perform the
 authentication challenge.
 */
@protocol NYPLSettingsAccountUIDelegate <NSObject>
@required
- (NSString *)username;
- (NSString *)pin;
@end

/**
 A class responsible for handling the authentication challenge initiated
 by the URLSession used in a Settings Account UI context.
 */
@interface NYPLSettingsAccountURLSessionChallengeHandler : NSObject <NSURLSessionDelegate>

@property(weak) id<NYPLSettingsAccountUIDelegate> uiDelegate;

- (instancetype)initWithUIDelegate:(id<NYPLSettingsAccountUIDelegate>)uiDelegate;

@end
