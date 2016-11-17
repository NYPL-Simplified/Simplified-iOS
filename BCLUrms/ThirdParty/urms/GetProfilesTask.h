//
//  GetProfilesTask.h
//  cgp-sdk-ios
//
//  Created by yano on 2015/05/09.
//  Copyright (c) 2015年 com.sonydadj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UrmsTask.h"

@interface UrmsGetProfilesResult : NSObject
@property (nonatomic, copy) NSArray*  profiles; // Array of NSString*
@end

@interface UrmsGetProfilesTask : UrmsTask
@property (nonatomic, readonly) UrmsGetProfilesResult* result;
@end
