//
//  BCLUrmsError.m
//  BCLUrms
//
//  Created by Shane Meyer on 6/4/16.
//  Copyright © 2016 Bluefire Productions, LLC. All rights reserved.
//

#import "BCLUrmsError.h"
#import "Urms.h"

NSString * const BCLUrmsErrorDomain = @"BCLUrmsErrorDomain";

@implementation BCLUrmsError

+ (nonnull NSError *)errorWithCode:(BCLUrmsErrorCode)code {
	return [BCLUrmsError errorWithCode:code urmsError:nil];
}

+ (nonnull NSError *)errorWithCode:(BCLUrmsErrorCode)code urmsError:(nullable UrmsError *)urmsError {
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	if (urmsError != nil) {
		if (urmsError.errorCode != nil) {
			dict[@"URMSCode"] = urmsError.errorCode;
		}
		dict[@"URMSType"] = @((NSInteger)(urmsError.errorType));
	}
	return [[NSError alloc] initWithDomain:BCLUrmsErrorDomain code:code userInfo:dict];
}

@end
