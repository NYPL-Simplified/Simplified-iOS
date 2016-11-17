//
//  GetBookmarksTask.h
//  cgp-sdk-ios
//
//  Created by yano on 2015/05/11.
//  Copyright (c) 2015年 com.sonydadj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UrmsTask.h"

@interface UrmsGetBookmarksTask : UrmsTask
@property (nonatomic, copy) NSString* ccid;
@property (nonatomic, readonly, copy) NSArray* result; // array of UrmsBookmark*
@end
