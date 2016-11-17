//
//  BCLUrmsSwitchProfileRequest.m
//  BCLUrms
//
//  Created by Shane Meyer on 7/20/16.
//  Copyright © 2016 Bluefire Productions, LLC. All rights reserved.
//

#import "BCLUrmsSwitchProfileRequest.h"
#import "BCLUrmsError.h"
#import "Urms.h"

//
// Interfaces
//

@class BCLUrmsSwitchProfileRequestImpl;

@interface BCLUrmsSwitchProfileRequest () {
	@private BCLUrmsSwitchProfileRequestImpl *m_impl;
}

@end

@interface BCLUrmsSwitchProfileRequestImpl : NSObject {
	@private __weak BCLUrmsSwitchProfileRequest *m_request;
}

- (instancetype)initWithRequest:(BCLUrmsSwitchProfileRequest *)request
	profileName:(NSString *)profileName;
- (void)cancel;

@end

//
// Main class
//

@implementation BCLUrmsSwitchProfileRequest

- (nonnull instancetype)initWithDelegate:(nullable id <BCLUrmsSwitchProfileRequestDelegate>)delegate
	profileName:(nonnull NSString *)profileName
{
	if (self = [super init]) {
		self.delegate = delegate;
		m_impl = [[BCLUrmsSwitchProfileRequestImpl alloc] initWithRequest:self
			profileName:profileName];
	}
	return self;
}

- (void)dealloc {
	[m_impl cancel];
}

- (void)implDidFinishWithError:(NSError *)error {
	[self.delegate urmsSwitchProfileRequestDidFinish:self error:error];
}

@end

//
// Impl class
//

@implementation BCLUrmsSwitchProfileRequestImpl

- (instancetype)initWithRequest:(BCLUrmsSwitchProfileRequest *)request
	profileName:(NSString *)profileName
{
	if (self = [super init]) {
		m_request = request;

		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			if (m_request == nil) {
				return;
			}

			UrmsGetProfilesTask* getProfiles = [Urms createGetProfilesTask];

			getProfiles.onSucceeded = ^(UrmsGetProfilesTask *getProfilesTask) {
				BOOL found = NO;

				for (NSString *name in getProfilesTask.result.profiles) {
					if ([name isEqualToString:profileName]) {
						found = YES;
						break;
					}
				}

				if (found) {
					UrmsSwitchProfileTask *switchProfile = [Urms createSwitchProfileTask];
					switchProfile.profileName = profileName;

					switchProfile.onSucceeded = ^(UrmsSwitchProfileTask *task) {
						dispatch_async(dispatch_get_main_queue(), ^{
							[m_request implDidFinishWithError:nil];
						});
					};

					switchProfile.onFailed = ^(id task, UrmsError *error) {
						NSError *nserror = [BCLUrmsError errorWithCode:
							BCLUrmsErrorCodeSwitchProfile urmsError:error];
						dispatch_async(dispatch_get_main_queue(), ^{
							[m_request implDidFinishWithError:nserror];
						});
					};

					[switchProfile execute:YES];
				}
				else {
					NSError *nserror = [BCLUrmsError errorWithCode:BCLUrmsErrorCodeProfileNotFound];
					dispatch_async(dispatch_get_main_queue(), ^{
						[m_request implDidFinishWithError:nserror];
					});
				}
			};

			getProfiles.onFailed = ^(id task, UrmsError *error) {
				NSError *nserror = [BCLUrmsError errorWithCode:
					BCLUrmsErrorCodeSwitchProfile urmsError:error];
				dispatch_async(dispatch_get_main_queue(), ^{
					[m_request implDidFinishWithError:nserror];
				});
			};

			[getProfiles execute:YES];
		});
	}

	return self;
}

- (void)cancel {
	m_request = nil;
}

@end
