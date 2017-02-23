//
//  BCLUrmsEvaluateLicenseRequest.h
//  BCLUrms
//
//  Created by Shane Meyer on 6/4/16.
//  Copyright © 2016 Bluefire Productions, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BCLUrmsEvaluateLicenseRequest;

/**
	@brief The request delegate.
*/
@protocol BCLUrmsEvaluateLicenseRequestDelegate <NSObject>

/**
	@brief Called when the request has finished.
	@param request The request.
	@param error An error if the request failed, or @c nil if the license is valid.
*/
- (void)urmsEvaluateLicenseRequestDidFinish:(nonnull BCLUrmsEvaluateLicenseRequest *)request
	error:(nullable NSError *)error;

@end

/**
	@brief A @c BCLUrmsEvaluateLicenseRequest object represents a request that evaluates a book's
		license.

		In most cases an application can create a @c BCLUrmsEvaluateRequest object instead, which
		combines the tasks of license evaluation and book registration.
*/
@interface BCLUrmsEvaluateLicenseRequest : NSObject

/**
	@brief The request delegate.
*/
@property (nonatomic, weak, nullable) id <BCLUrmsEvaluateLicenseRequestDelegate> delegate;

/**
	@brief Creates and starts an asynchronous license evaluation request.
	@param delegate The request delegate.
	@param ccid The CCID of the book.
	@param profileName The name of the URMS profile.
	@return A @c BCLUrmsEvaluateLicenseRequest object.
*/
- (nonnull instancetype)
	initWithDelegate:(nullable id <BCLUrmsEvaluateLicenseRequestDelegate>)delegate
	ccid:(nonnull NSString *)ccid
	profileName:(nonnull NSString *)profileName;

@end
