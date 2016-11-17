//
//  BCLUrmsRegisterBookRequest.h
//  BCLUrms
//
//  Created by Shane Meyer on 6/4/16.
//  Copyright © 2016 Bluefire Productions, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BCLUrmsRegisterBookRequest;

@protocol BCLUrmsRegisterBookRequestDelegate <NSObject>

- (void)urmsRegisterBookRequestDidFinish:(nonnull BCLUrmsRegisterBookRequest *)request
	error:(nullable NSError *)error;

@end

@interface BCLUrmsRegisterBookRequest : NSObject

@property (nonatomic, weak, nullable) id <BCLUrmsRegisterBookRequestDelegate> delegate;

- (nonnull instancetype)
	initWithDelegate:(nullable id <BCLUrmsRegisterBookRequestDelegate>)delegate
	ccid:(nonnull NSString *)ccid
	profileName:(nonnull NSString *)profileName
	path:(nonnull NSString *)path;

@end
