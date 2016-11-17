//
//  BCLUrmsEvaluateLicenseRequest.h
//  BCLUrms
//
//  Created by Shane Meyer on 6/4/16.
//  Copyright © 2016 Bluefire Productions, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BCLUrmsEvaluateLicenseRequest;

@protocol BCLUrmsEvaluateLicenseRequestDelegate <NSObject>

- (void)urmsEvaluateLicenseRequestDidFinish:(nonnull BCLUrmsEvaluateLicenseRequest *)request
	error:(nullable NSError *)error;

@end

@interface BCLUrmsEvaluateLicenseRequest : NSObject

@property (nonatomic, weak, nullable) id <BCLUrmsEvaluateLicenseRequestDelegate> delegate;

- (nonnull instancetype)
	initWithDelegate:(nullable id <BCLUrmsEvaluateLicenseRequestDelegate>)delegate
	ccid:(nonnull NSString *)ccid
	profileName:(nonnull NSString *)profileName;

@end
