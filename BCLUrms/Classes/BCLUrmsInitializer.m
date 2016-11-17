//
//  BCLUrmsInitializer.m
//  BCLUrms
//
//  Created by Shane Meyer on 7/22/16.
//  Copyright © 2016 Bluefire Productions, LLC. All rights reserved.
//

#import "BCLUrmsInitializer.h"
#import "BCLUrmsInitializeRequest.h"

@implementation BCLUrmsInitializer

+ (void)initializeWithMarlinURL:(nonnull NSString *)marlinURL {

	// Pass along the marlin URL to the BCLUrmsInitializeRequest class, which is a convenient
	// non-public class where we can store this value, and later retrieve it from
	// BCLUrmsCreateProfileRequest.

	if ([BCLUrmsInitializeRequest getMarlinURL] == nil) {
		[BCLUrmsInitializeRequest setMarlinURL:marlinURL];
	}
}

@end
