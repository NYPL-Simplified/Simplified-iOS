//
//  BCLUrmsInitializeRequest.h
//  BCLUrms
//
//  Created by Shane Meyer on 7/20/16.
//  Copyright © 2016 Bluefire Productions, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BCLUrmsInitializeRequest;

@protocol BCLUrmsInitializeRequestDelegate <NSObject>

- (void)urmsInitializeRequestDidFinish:(nonnull BCLUrmsInitializeRequest *)request
	error:(nullable NSError *)error;

@end

@interface BCLUrmsInitializeRequest : NSObject

@property (nonatomic, weak, nullable) id <BCLUrmsInitializeRequestDelegate> delegate;

- (nonnull instancetype)initWithDelegate:(nullable id <BCLUrmsInitializeRequestDelegate>)delegate
	profileName:(nonnull NSString *)profileName;
+ (nullable NSString *)getMarlinURL;
+ (void)setMarlinURL:(nonnull NSString *)marlinURL;

@end
