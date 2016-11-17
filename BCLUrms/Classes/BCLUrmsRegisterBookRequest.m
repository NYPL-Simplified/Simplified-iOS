//
//  BCLUrmsRegisterBookRequest.m
//  BCLUrms
//
//  Created by Shane Meyer on 6/4/16.
//  Copyright © 2016 Bluefire Productions, LLC. All rights reserved.
//

#import "BCLUrmsRegisterBookRequest.h"
#import "BCLUrmsError.h"
#import "BCLUrmsInitializeRequest.h"
#import "Urms.h"

//
// Interfaces
//

@class BCLUrmsRegisterBookRequestImpl;

@interface BCLUrmsRegisterBookRequest () <BCLUrmsInitializeRequestDelegate> {
	@private NSString *m_ccid;
	@private BCLUrmsRegisterBookRequestImpl *m_impl;
	@private BCLUrmsInitializeRequest *m_initializeRequest;
	@private NSString *m_path;
}

@end

@interface BCLUrmsRegisterBookRequestImpl : NSObject {
	@private __weak BCLUrmsRegisterBookRequest *m_request;
}

- (instancetype)initWithRequest:(BCLUrmsRegisterBookRequest *)request
	ccid:(NSString *)ccid path:(NSString *)path;
- (void)cancel;

@end

//
// Main class
//

@implementation BCLUrmsRegisterBookRequest

- (nonnull instancetype)
	initWithDelegate:(nullable id <BCLUrmsRegisterBookRequestDelegate>)delegate
	ccid:(nonnull NSString *)ccid
	profileName:(nonnull NSString *)profileName
	path:(nonnull NSString *)path
{
	if (self = [super init]) {
		self.delegate = delegate;
		m_ccid = ccid;
		m_path = path;
		m_initializeRequest = [[BCLUrmsInitializeRequest alloc]
			initWithDelegate:self profileName:profileName];
	}
	return self;
}

- (void)dealloc {
	[m_impl cancel];
}

- (void)implDidFinishWithError:(NSError *)error {
	[self.delegate urmsRegisterBookRequestDidFinish:self error:error];
}

- (void)urmsInitializeRequestDidFinish:(BCLUrmsInitializeRequest *)request error:(NSError *)error {
	if (error != nil) {
		[self.delegate urmsRegisterBookRequestDidFinish:self error:error];
	}
	else {
		m_impl = [[BCLUrmsRegisterBookRequestImpl alloc]
			initWithRequest:self ccid:m_ccid path:m_path];
	}
	m_initializeRequest = nil;
}

@end

//
// Impl class
//

@implementation BCLUrmsRegisterBookRequestImpl

- (instancetype)initWithRequest:(BCLUrmsRegisterBookRequest *)request
	ccid:(NSString *)ccid path:(NSString *)path
{
	if (self = [super init]) {
		m_request = request;

		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			if (m_request == nil) {
				return;
			}

			if (ccid == nil || path == nil) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[m_request implDidFinishWithError:[BCLUrmsError errorWithCode:
						BCLUrmsErrorCodeRegisterBook urmsError:nil]];
				});
				return;
			}

			UrmsRegisterBookTask *task = [Urms createRegisterBookTask:ccid];
			task.destination = path;

			task.onSucceeded = ^(id task) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[m_request implDidFinishWithError:nil];
				});
			};

			task.onFailed = ^(id task, UrmsError *error) {
				NSError *nserror = [BCLUrmsError errorWithCode:
					BCLUrmsErrorCodeRegisterBook urmsError:error];
				dispatch_async(dispatch_get_main_queue(), ^{
					[m_request implDidFinishWithError:nserror];
				});
			};

			[task executeAsync];
		});
	}

	return self;
}

- (void)cancel {
	m_request = nil;
}

@end
