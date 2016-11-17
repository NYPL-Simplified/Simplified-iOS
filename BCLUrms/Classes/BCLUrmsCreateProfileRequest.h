//
//  BCLUrmsCreateProfileRequest.h
//  BCLUrms
//
//  Created by Shane Meyer on 6/4/16.
//  Copyright © 2016 Bluefire Productions, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BCLUrmsCreateProfileRequest;

@protocol BCLUrmsCreateProfileRequestDelegate <NSObject>

- (void)urmsCreateProfileRequestDidFinish:(nonnull BCLUrmsCreateProfileRequest *)request
	error:(nullable NSError *)error;

@end

@interface BCLUrmsCreateProfileRequest : NSObject

@property (nonatomic, weak, nullable) id <BCLUrmsCreateProfileRequestDelegate> delegate;

- (nonnull instancetype)initWithDelegate:(nullable id <BCLUrmsCreateProfileRequestDelegate>)delegate
	authToken:(nonnull NSString *)authToken profileName:(nonnull NSString *)profileName;

@end
