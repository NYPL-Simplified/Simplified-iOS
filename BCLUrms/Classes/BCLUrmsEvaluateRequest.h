//
//  BCLUrmsEvaluateRequest.h
//  BCLUrms
//
//  Created by Shane Meyer on 6/4/16.
//  Copyright © 2016 Bluefire Productions, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BCLUrmsEvaluateRequest;

@protocol BCLUrmsEvaluateRequestDelegate <NSObject>

- (void)urmsEvaluateRequestDidFinish:(nonnull BCLUrmsEvaluateRequest *)request
	error:(nullable NSError *)error;

@end

@interface BCLUrmsEvaluateRequest : NSObject

@property (nonatomic, weak, nullable) id <BCLUrmsEvaluateRequestDelegate> delegate;

- (nonnull instancetype)
	initWithDelegate:(nullable id <BCLUrmsEvaluateRequestDelegate>)delegate
	ccid:(nonnull NSString *)ccid
	profileName:(nonnull NSString *)profileName
	path:(nonnull NSString *)path;

@end
