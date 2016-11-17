//
//  BCLUrmsInitializeRequest.m
//  BCLUrms
//
//  Created by Shane Meyer on 7/20/16.
//  Copyright © 2016 Bluefire Productions, LLC. All rights reserved.
//

#import "BCLUrmsInitializeRequest.h"
#import "BCLUrmsError.h"
#import "BCLUrmsSwitchProfileRequest.h"
#import "Urms.h"

static NSInteger m_initializedState = 0;
static NSString *m_marlinURL = nil;

@interface BCLUrmsInitializeRequest () <BCLUrmsSwitchProfileRequestDelegate> {
	@private BCLUrmsSwitchProfileRequest *m_switchRequest;
}

@end

@implementation BCLUrmsInitializeRequest

- (nonnull instancetype)initWithDelegate:(nullable id <BCLUrmsInitializeRequestDelegate>)delegate
	profileName:(nonnull NSString *)profileName
{
	if (self = [super init]) {
		self.delegate = delegate;
		__weak BCLUrmsInitializeRequest *wself = self;
		dispatch_async(dispatch_get_main_queue(), ^{
			[wself goWithProfileName:profileName];
		});
	}
	return self;
}

+ (nullable NSString *)getMarlinURL {
	return m_marlinURL;
}

- (void)goWithProfileName:(NSString *)profileName {
	if (m_initializedState == 0) {
		if (m_marlinURL == nil || m_marlinURL.length == 0) {
			NSLog(@"The marlin URL is missing! Call BCLUrmsInitializer to provide.");
			NSError *e = [BCLUrmsError errorWithCode:BCLUrmsErrorCodeInitialization urmsError:nil];
			[self.delegate urmsInitializeRequestDidFinish:self error:e];
			return;
		}

		UrmsError *error = [Urms initialize:15
			keyChainServiceID:@"DenuvoService"
			keyChainVendorIDGroup:@"com.denuvo.URMS-App"];

		if (error != nil && error.isError) {
			NSError *e = [BCLUrmsError errorWithCode:BCLUrmsErrorCodeInitialization urmsError:error];
			[self.delegate urmsInitializeRequestDidFinish:self error:e];
			return;
		}

		m_initializedState = 1;
	}

	if (m_initializedState == 1) {
		m_switchRequest = [[BCLUrmsSwitchProfileRequest alloc]
			initWithDelegate:self profileName:profileName];
	}
	else {
		[self.delegate urmsInitializeRequestDidFinish:self error:nil];
	}
}

+ (void)setMarlinURL:(nonnull NSString *)marlinURL {
	m_marlinURL = marlinURL;
}

- (void)urmsSwitchProfileRequestDidFinish:(BCLUrmsSwitchProfileRequest *)request
	error:(NSError *)error
{
	[self.delegate urmsInitializeRequestDidFinish:self error:error];
	m_switchRequest = nil;
}

@end
