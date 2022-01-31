//
//  NYPLSAMLHelper.h
//  Simplified
//
//  Created by Ettore Pasquini on 10/21/20.
//  Copyright © 2020 NYPL. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NYPLSignInBusinessLogic;

@interface NYPLSAMLHelper : NSObject

@property (weak) NYPLSignInBusinessLogic *businessLogic;

// Log in via SAML.
- (void)logIn;

@end
