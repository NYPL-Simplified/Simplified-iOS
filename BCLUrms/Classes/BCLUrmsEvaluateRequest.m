//
//  BCLUrmsEvaluateRequest.m
//  BCLUrms
//
//  Created by Shane Meyer on 6/4/16.
//  Copyright © 2016 Bluefire Productions, LLC. All rights reserved.
//

#import "BCLUrmsEvaluateRequest.h"
#import "BCLUrmsEvaluateLicenseRequest.h"
#import "BCLUrmsRegisterBookRequest.h"

@interface BCLUrmsEvaluateRequest () <
	BCLUrmsEvaluateLicenseRequestDelegate,
	BCLUrmsRegisterBookRequestDelegate>
{
	@private BOOL m_alreadyEvaluatedLicense;
	@private NSString *m_ccid;
	@private BCLUrmsEvaluateLicenseRequest *m_evaluateLicenseRequest;
	@private NSString *m_path;
	@private NSString *m_profileName;
	@private BCLUrmsRegisterBookRequest *m_registerBookRequest;
}

@end

@implementation BCLUrmsEvaluateRequest

- (nonnull instancetype)
	initWithDelegate:(nullable id <BCLUrmsEvaluateRequestDelegate>)delegate
	ccid:(nonnull NSString *)ccid
	profileName:(nonnull NSString *)profileName
	path:(nonnull NSString *)path
{
	if (self = [super init]) {
		m_alreadyEvaluatedLicense = NO;
		m_ccid = ccid;
		m_path = path;
		m_profileName = profileName;

		self.delegate = delegate;

		m_evaluateLicenseRequest = [[BCLUrmsEvaluateLicenseRequest alloc]
			initWithDelegate:self ccid:ccid profileName:profileName];
	}
	return self;
}

- (void)urmsEvaluateLicenseRequestDidFinish:(BCLUrmsEvaluateLicenseRequest *)request
	error:(NSError *)error
{
	if (error != nil) {
		if (m_alreadyEvaluatedLicense) {
			[self.delegate urmsEvaluateRequestDidFinish:self error:error];
		}
		else {
			m_alreadyEvaluatedLicense = YES;
			m_registerBookRequest = [[BCLUrmsRegisterBookRequest alloc]
				initWithDelegate:self ccid:m_ccid profileName:m_profileName path:m_path];
		}
	}
	else {
		[self.delegate urmsEvaluateRequestDidFinish:self error:error];
	}
	m_evaluateLicenseRequest = nil;
}

- (void)urmsRegisterBookRequestDidFinish:(BCLUrmsRegisterBookRequest *)request
	error:(NSError *)error
{
	if (error != nil) {
		[self.delegate urmsEvaluateRequestDidFinish:self error:error];
	}
	else {
		m_evaluateLicenseRequest = [[BCLUrmsEvaluateLicenseRequest alloc]
			initWithDelegate:self ccid:m_ccid profileName:m_profileName];
	}
	m_registerBookRequest = nil;
}

@end
