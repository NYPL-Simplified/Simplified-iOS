//
//  BCLUrmsError.h
//  BCLUrms
//
//  Created by Shane Meyer on 6/4/16.
//  Copyright © 2016 Bluefire Productions, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BCLUrmsEnum.h"

@class UrmsError;

@interface BCLUrmsError : NSObject

+ (nonnull NSError *)errorWithCode:(BCLUrmsErrorCode)code;
+ (nonnull NSError *)errorWithCode:(BCLUrmsErrorCode)code urmsError:(nullable UrmsError *)urmsError;

@end
