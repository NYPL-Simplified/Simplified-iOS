//
//  BCLUrmsSwitchProfileRequest.h
//  BCLUrms
//
//  Created by Shane Meyer on 7/20/16.
//  Copyright © 2016 Bluefire Productions, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BCLUrmsSwitchProfileRequest;

@protocol BCLUrmsSwitchProfileRequestDelegate <NSObject>

- (void)urmsSwitchProfileRequestDidFinish:(nonnull BCLUrmsSwitchProfileRequest *)request
	error:(nullable NSError *)error;

@end

@interface BCLUrmsSwitchProfileRequest : NSObject

@property (nonatomic, weak, nullable) id <BCLUrmsSwitchProfileRequestDelegate> delegate;

- (nonnull instancetype)initWithDelegate:(nullable id <BCLUrmsSwitchProfileRequestDelegate>)delegate
	profileName:(nonnull NSString *)profileName;

@end
