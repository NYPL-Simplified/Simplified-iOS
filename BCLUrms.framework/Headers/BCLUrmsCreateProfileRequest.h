//
//  BCLUrmsCreateProfileRequest.h
//  BCLUrms
//
//  Created by Shane Meyer on 6/4/16.
//  Copyright © 2016 Bluefire Productions, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BCLUrmsCreateProfileRequest;

/**
	@brief The request delegate.
*/
@protocol BCLUrmsCreateProfileRequestDelegate <NSObject>

/**
	@brief Called when the request has finished.
	@param request The request.
	@param error An error if the request failed.
*/
- (void)urmsCreateProfileRequestDidFinish:(nonnull BCLUrmsCreateProfileRequest *)request
	error:(nullable NSError *)error;

@end

/**
	@brief A @c BCLUrmsCreateProfileRequest object represents a request that creates a URMS profile.
*/
@interface BCLUrmsCreateProfileRequest : NSObject

/**
	@brief The request delegate.
*/
@property (nonatomic, weak, nullable) id <BCLUrmsCreateProfileRequestDelegate> delegate;

/**
	@brief Creates and starts an asynchronous profile creation request.
	@param delegate The request delegate.
	@param authToken The URMS auth token provided by the back end.
	@param profileName The name of the URMS profile.
	@return A @c BCLUrmsCreateProfileRequest object.
*/
- (nonnull instancetype)initWithDelegate:(nullable id <BCLUrmsCreateProfileRequestDelegate>)delegate
	authToken:(nonnull NSString *)authToken profileName:(nonnull NSString *)profileName;

@end
