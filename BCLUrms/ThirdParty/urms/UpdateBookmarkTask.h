//
//  UpdateBookmarkTask.h
//  cgp-sdk-ios
//
//  Created by yano on 2015/05/11.
//  Copyright (c) 2015年 com.sonydadj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UrmsTask.h"

@interface UrmsUpdateBookmarkTask : UrmsTask
@property (nonatomic, copy) NSString* tag;
@property (nonatomic, copy) NSString* content;
@property (nonatomic) NSInteger type;
@property (nonatomic) NSInteger bookmarkId;
@property (nonatomic) int64_t updatedAt;
@end
