//
//  BCLUrmsCreateProfileRequest.m
//  BCLUrms
//
//  Created by Shane Meyer on 6/4/16.
//  Copyright © 2016 Bluefire Productions, LLC. All rights reserved.
//

#import "BCLUrmsCreateProfileRequest.h"
#import "BCLUrms.h"
#import "BCLUrmsError.h"
#import "BCLUrmsInitializeRequest.h"
#import "Urms.h"

//
// Interfaces
//

@class BCLUrmsCreateProfileRequestImpl;

@interface BCLUrmsCreateProfileRequest () <BCLUrmsInitializeRequestDelegate> {
	@private NSString *m_authToken;
	@private BCLUrmsCreateProfileRequestImpl *m_impl;
	@private BCLUrmsInitializeRequest *m_initializeRequest;
	@private NSString *m_profileName;
}

@end

@interface BCLUrmsCreateProfileRequestImpl : NSObject {
	@private __weak BCLUrmsCreateProfileRequest *m_request;
}

- (instancetype)initWithRequest:(BCLUrmsCreateProfileRequest *)request
	authToken:(NSString *)authToken profileName:(NSString *)profileName;
- (void)cancel;

@end

//
// Main class
//

@implementation BCLUrmsCreateProfileRequest

- (nonnull instancetype)initWithDelegate:(nullable id <BCLUrmsCreateProfileRequestDelegate>)delegate
	authToken:(nonnull NSString *)authToken profileName:(nonnull NSString *)profileName
{
	if (self = [super init]) {
		self.delegate = delegate;
		m_authToken = authToken;
		m_profileName = profileName;
		m_initializeRequest = [[BCLUrmsInitializeRequest alloc]
			initWithDelegate:self profileName:profileName];
	}
	return self;
}

- (void)dealloc {
	[m_impl cancel];
}

- (void)implDidFinishWithError:(NSError *)error {
	[self.delegate urmsCreateProfileRequestDidFinish:self error:error];
}

- (void)urmsInitializeRequestDidFinish:(BCLUrmsInitializeRequest *)request error:(NSError *)error {
	BOOL profileNotFound =
		error != nil &&
		error.domain != nil &&
		[error.domain isEqualToString:BCLUrmsErrorDomain] &&
		error.code == BCLUrmsErrorCodeProfileNotFound;

	// It's expected that we won't find the profile. We're about to create it.

	if (error != nil && !profileNotFound) {
		[self.delegate urmsCreateProfileRequestDidFinish:self error:error];
	}
	else {
		m_impl = [[BCLUrmsCreateProfileRequestImpl alloc] initWithRequest:self
			authToken:m_authToken profileName:m_profileName];
	}

	m_initializeRequest = nil;
}

@end

//
// Impl class
//

@implementation BCLUrmsCreateProfileRequestImpl

- (instancetype)initWithRequest:(BCLUrmsCreateProfileRequest *)request
	authToken:(NSString *)authToken profileName:(NSString *)profileName
{
	if (self = [super init]) {
		m_request = request;

		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			if (m_request == nil) {
				return;
			}

			if (authToken == nil) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[m_request implDidFinishWithError:[BCLUrmsError errorWithCode:
						BCLUrmsErrorCodeCreateProfile urmsError:nil]];
				});
				return;
			}

			UrmsProfileConfiguration *config = [[UrmsProfileConfiguration alloc] init];
			config.cgpUrl = @"https://urms-sdk.codefusion.technology/sdk/";
			config.marlinService = @"urn:marlin:organization:sne:service-provider:2";
			config.marlinUrl = [BCLUrmsInitializeRequest getMarlinURL];
			config.useSSL = 1;

			UrmsCreateProfileTask *createProfile = [Urms createCreateProfileTask];
			createProfile.authToken = authToken;
			createProfile.config = config;
			createProfile.deviceName = nil;
			createProfile.profileName = profileName;

			createProfile.onSucceeded = ^(UrmsCreateProfileTask *task) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[m_request implDidFinishWithError:nil];
				});
			};

			createProfile.onFailed = ^(id task, UrmsError *error) {
				NSError *nserror = [BCLUrmsError errorWithCode:
					BCLUrmsErrorCodeCreateProfile urmsError:error];
				dispatch_async(dispatch_get_main_queue(), ^{
					[m_request implDidFinishWithError:nserror];
				});
			};

			[createProfile executeAsync];
		});
	}

	return self;
}

- (void)cancel {
	m_request = nil;
}

@end
