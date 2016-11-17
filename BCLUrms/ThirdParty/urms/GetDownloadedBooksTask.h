//
//  GetDownloadedBooksTask.h
//  cgp-sdk-ios
//
//  Created by yano on 2015/05/09.
//  Copyright (c) 2015年 com.sonydadj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UrmsTask.h"

@interface UrmsGetDownloadedBooksResult : NSObject
@property (nonatomic, copy) NSArray* books;
@property (nonatomic) NSInteger totalCount;
@end


@interface UrmsGetDownloadedBooksTask : UrmsTask
@property (nonatomic, readonly) UrmsGetDownloadedBooksResult* result;
@end
