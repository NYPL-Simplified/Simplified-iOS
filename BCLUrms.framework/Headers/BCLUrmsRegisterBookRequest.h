//
//  BCLUrmsRegisterBookRequest.h
//  BCLUrms
//
//  Created by Shane Meyer on 6/4/16.
//  Copyright © 2016 Bluefire Productions, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BCLUrmsRegisterBookRequest;

/**
	@brief The request delegate.
*/
@protocol BCLUrmsRegisterBookRequestDelegate <NSObject>

/**
	@brief Called when the request has finished.
	@param request The request.
	@param error An error if the request failed.
*/
- (void)urmsRegisterBookRequestDidFinish:(nonnull BCLUrmsRegisterBookRequest *)request
	error:(nullable NSError *)error;

@end

/**
	@brief A @c BCLUrmsRegisterBookRequest object represents a request that registers a book.

		In most cases an application can create a @c BCLUrmsEvaluateRequest object instead, which
		combines the tasks of license evaluation and book registration.
*/
@interface BCLUrmsRegisterBookRequest : NSObject

/**
	@brief The request delegate.
*/
@property (nonatomic, weak, nullable) id <BCLUrmsRegisterBookRequestDelegate> delegate;

/**
	@brief Creates and starts an asynchronous book registration request.
	@param delegate The request delegate.
	@param ccid The CCID of the book.
	@param profileName The name of the URMS profile.
	@param path The local filesystem path of the book.
	@return A @c BCLUrmsRegisterBookRequest object.
*/
- (nonnull instancetype)
	initWithDelegate:(nullable id <BCLUrmsRegisterBookRequestDelegate>)delegate
	ccid:(nonnull NSString *)ccid
	profileName:(nonnull NSString *)profileName
	path:(nonnull NSString *)path;

@end
