//
//  BCLUrmsEvaluateRequest.h
//  BCLUrms
//
//  Created by Shane Meyer on 6/4/16.
//  Copyright © 2016 Bluefire Productions, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BCLUrmsEvaluateRequest;

/**
	@brief The request delegate.
*/
@protocol BCLUrmsEvaluateRequestDelegate <NSObject>

/**
	@brief Called when the request has finished.
	@param request The request.
	@param error An error if the request failed, or @c nil if the license is valid.
*/
- (void)urmsEvaluateRequestDidFinish:(nonnull BCLUrmsEvaluateRequest *)request
	error:(nullable NSError *)error;

@end

/**
	@brief A @c BCLUrmsEvaluateRequest object represents a request that combines the tasks of
		license evaluation and book registration.

		In most cases this class can be used as a convenience, rather than using
		@c BCLUrmsEvaluateLicenseRequest or @c BCLUrmsRegisterBookRequest directly. This class
		evaluates the book's license. If it succeeds, the delegate informs the caller of success.
		If it fails, and if the failure is due to a book registration issue, a book registration
		request is created. If that succeeds, then once again the license is evaluated.
*/
@interface BCLUrmsEvaluateRequest : NSObject

/**
	@brief The request delegate.
*/
@property (nonatomic, weak, nullable) id <BCLUrmsEvaluateRequestDelegate> delegate;

/**
	@brief Creates and starts an asynchronous evaluation request.
	@param delegate The request delegate.
	@param ccid The CCID of the book.
	@param profileName The name of the URMS profile.
	@param path The local filesystem path of the book.
	@return A @c BCLUrmsEvaluateRequest object.
*/
- (nonnull instancetype)
	initWithDelegate:(nullable id <BCLUrmsEvaluateRequestDelegate>)delegate
	ccid:(nonnull NSString *)ccid
	profileName:(nonnull NSString *)profileName
	path:(nonnull NSString *)path;

@end
