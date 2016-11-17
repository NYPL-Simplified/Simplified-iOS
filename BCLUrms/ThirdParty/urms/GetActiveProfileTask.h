//
//  GetActiveProfileTask.h
//  cgp-sdk-ios
//
//  Created by yano on 2015/05/09.
//  Copyright (c) 2015年 com.sonydadj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UrmsTask.h"

@interface UrmsGetActiveProfileResult : NSObject
@property (nonatomic, copy) NSString* profile;
@end

@interface UrmsGetActiveProfileTask : UrmsTask
@property (nonatomic, readonly) UrmsGetActiveProfileResult* result;
@end
