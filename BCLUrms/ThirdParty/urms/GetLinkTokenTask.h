//
//  GetLinkTokenTask.h
//  cgp-sdk-ios
//
//  Created by fbures on 2015/08/25.
//  Copyright (c) 2015年 com.sonydadj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UrmsTask.h"

@interface UrmsGetLinkTokenResult : NSObject
@property (nonatomic, copy) NSString* token;
@end

@interface UrmsGetLinkTokenTask : UrmsTask
@property (nonatomic, readonly) UrmsGetLinkTokenResult* result;
@end
