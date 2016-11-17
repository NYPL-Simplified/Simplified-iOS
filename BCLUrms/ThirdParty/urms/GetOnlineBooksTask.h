//
//  GetOnlineBooksTask.h
//  cgp-sdk-ios
//
//  Created by yano on 2015/05/09.
//  Copyright (c) 2015年 com.sonydadj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UrmsTask.h"

@interface UrmsGetOnlineBooksResult : NSObject
@property (nonatomic, copy) NSArray*  books; // Array of UrmsBook*
@property (nonatomic)       NSInteger totalCount;
@end

@interface UrmsGetOnlineBooksTask : UrmsTask
- (id) init;

@property (nonatomic) Boolean containsOwn;
@property (nonatomic) Boolean containsLending;
@property (nonatomic) Boolean containsSelling;
@property (nonatomic) Boolean containsBorrowing;
@property (nonatomic) Boolean containsGroup;
@property (nonatomic) Boolean containsCommonBookshelf;
@property (nonatomic) UrmsBookFormat bookFormat;
@property (nonatomic) NSInteger groupId;
@property (nonatomic) NSInteger page;
@property (nonatomic) NSInteger pageSize;

@property (nonatomic, readonly) UrmsGetOnlineBooksResult* result;
@end
