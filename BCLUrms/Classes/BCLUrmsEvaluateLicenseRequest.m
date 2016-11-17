//
//  BCLUrmsEvaluateLicenseRequest.m
//  BCLUrms
//
//  Created by Shane Meyer on 6/4/16.
//  Copyright © 2016 Bluefire Productions, LLC. All rights reserved.
//

#import "BCLUrmsEvaluateLicenseRequest.h"
#import "BCLUrmsError.h"
#import "BCLUrmsInitializeRequest.h"
#import "Urms.h"

//
// Interfaces
//

@class BCLUrmsEvaluateLicenseRequestImpl;

@interface BCLUrmsEvaluateLicenseRequest () <BCLUrmsInitializeRequestDelegate> {
	@private NSString *m_ccid;
	@private BCLUrmsEvaluateLicenseRequestImpl *m_impl;
	@private BCLUrmsInitializeRequest *m_initializeRequest;
}

@end

@interface BCLUrmsEvaluateLicenseRequestImpl : NSObject {
	@private __weak BCLUrmsEvaluateLicenseRequest *m_request;
}

- (instancetype)initWithRequest:(BCLUrmsEvaluateLicenseRequest *)request ccid:(NSString *)ccid;
- (void)cancel;

@end

//
// Main class
//

@implementation BCLUrmsEvaluateLicenseRequest

- (nonnull instancetype)
	initWithDelegate:(nullable id <BCLUrmsEvaluateLicenseRequestDelegate>)delegate
	ccid:(nonnull NSString *)ccid
	profileName:(nonnull NSString *)profileName
{
	if (self = [super init]) {
		self.delegate = delegate;
		m_ccid = ccid;
		m_initializeRequest = [[BCLUrmsInitializeRequest alloc]
			initWithDelegate:self profileName:profileName];
	}
	return self;
}

- (void)dealloc {
	[m_impl cancel];
}

- (void)implDidFinishWithError:(NSError *)error {
	[self.delegate urmsEvaluateLicenseRequestDidFinish:self error:error];
}

- (void)urmsInitializeRequestDidFinish:(BCLUrmsInitializeRequest *)request error:(NSError *)error {
	if (error != nil) {
		[self.delegate urmsEvaluateLicenseRequestDidFinish:self error:error];
	}
	else {
		m_impl = [[BCLUrmsEvaluateLicenseRequestImpl alloc] initWithRequest:self ccid:m_ccid];
	}
	m_initializeRequest = nil;
}

@end

//
// Impl class
//

@implementation BCLUrmsEvaluateLicenseRequestImpl

- (instancetype)initWithRequest:(BCLUrmsEvaluateLicenseRequest *)request ccid:(NSString *)ccid {
	if (self = [super init]) {
		m_request = request;

		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			if (m_request == nil) {
				return;
			}

			NSError *error = nil;
			if (ccid != nil && [[Urms createEvaluateLicenseTask:ccid] execute]) {
				// The license is good.
			}
			else {
				error = [BCLUrmsError errorWithCode:BCLUrmsErrorCodeLicenseInvalid];
			}

			dispatch_async(dispatch_get_main_queue(), ^{
				[m_request implDidFinishWithError:error];
			});
		});
	}
	return self;
}

- (void)cancel {
	m_request = nil;
}

@end
