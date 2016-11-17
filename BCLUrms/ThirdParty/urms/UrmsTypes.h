//
//  UrmsTypes.h
//  cgp-sdk-ios
//
//  Created by yano on 2015/05/07.
//  Copyright (c) 2015年 com.sonydadj. All rights reserved.
//

#ifndef _URMSTYPES_H
#define _URMSTYPES_H

#import <Foundation/Foundation.h>

typedef enum _urms_task_status {
    UrmsTaskCreated = 0,
    UrmsTaskExecuting = 16,
    _UrmsTaskCompleted = 32,
    UrmsTaskSucceeded,
    UrmsTaskFailed,
    UrmsTaskCancelled
} UrmsTaskStatus;

typedef enum _urms_book_format {
    UrmsBookFormatPdf = 0,
    UrmsBookFormatEpub2 = 1,
    UrmsBookFormatEpub3 = 2,
    UrmsBookFormatAll = 3
} UrmsBookFormat;

typedef enum _urms_content_status : uint32_t {
    UrmsContentStatusNone = 0,
    UrmsContentStatusLend,
    UrmsContentStatusStoreLend,
    UrmsContentStatusBorrow
} UrmsContentStatus;

typedef enum _urms_book_status : uint32_t
{
    UrmsBookStatusNone = 0x0000,
    UrmsBookStatusCanRead = 0x0001,
    UrmsBookStatusCanLend = 0x0002,
    UrmsBookStatusCanReturn = 0x0004,
    UrmsBookStatusCanGetback = 0x0008,
    UrmsBookStatusCanSell = 0x0010,
    UrmsBookStatusCanCanselSelling = 0x0020,
    UrmsBookStatusCanBindToGroup = 0x0040,
    UrmsBookStatusCanUnbindFromGroup = 0x0080,
    UrmsBookStatusOwn = 0x0100,
    UrmsBookStatusInMainBookshelf = 0x0200,
    UrmsBookStatusInSharedBookshelf = 0x0400,
    UrmsBookStatusInGroup = 0x0800,
    UrmsBookStatusInMyGroup = 0x1000,
} UrmsBookStatus;

typedef enum _urms_group_status : uint32_t
{
    UrmsGroupStatusAdmin = 0,
    UrmsGroupStatusMember = 1,
    UrmsGroupStatusAll = 2
} UrmsGroupStatus;

@interface UrmsBook : NSObject
@property (nonatomic, copy) NSString* ccid;
@property (nonatomic, copy) NSString* externalId;
@property (nonatomic, copy) NSString* title;
@property (nonatomic, copy) NSString* storeName;
@property (nonatomic, copy) NSString* thumbnailUrl;
@property (nonatomic) UrmsBookFormat format;
@property (nonatomic) UrmsBookStatus status;
@property (nonatomic) NSInteger ageLimit;
@property (nonatomic) NSInteger version;
@property (nonatomic) id extra;

- (Boolean) isCanRead;
- (Boolean) isContainsStatus:(UrmsBookStatus)status;
@end

@interface UrmsDownloadedBook : UrmsBook
@property (nonatomic) NSInteger durationCopy;
@property (nonatomic) NSInteger countCopy;
@property (nonatomic) NSInteger durationPrint;
@property (nonatomic) NSInteger countPrint;
@property (nonatomic) NSInteger resolutionPrint;
@property (nonatomic, copy) NSString *periodCopy;
@property (nonatomic, copy) NSString *periodPrint;
@end

@interface UrmsBookmark : NSObject
@property (nonatomic, copy) NSString   *ccid;
@property (nonatomic, copy) NSString   *tag;
@property (nonatomic, copy) NSString   *content;
@property (nonatomic) NSInteger        bookmarkId;
@property (nonatomic) int64_t          lastUpdated;
@property (nonatomic) NSInteger        type;
@property (nonatomic) id extra;
@end

@interface UrmsGroup : NSObject
@property (nonatomic) NSInteger groupId;
@property (nonatomic, copy) NSString *groupName;
@property (nonatomic, copy) NSString *adminId;
@property (nonatomic) NSArray *userIds; // NSString*
@property (nonatomic) NSArray *books;   // UrmsBook*
@property (nonatomic) id extra;
@end

@interface UrmsOwnBook : NSObject
@property (nonatomic) UrmsBookStatus status;
@property (nonatomic) id extra;
@end

@interface UrmsCommonBookshelfBook : NSObject
@property (nonatomic, copy) NSString       *userId;
@property (nonatomic)       UrmsBookStatus status;
@property (nonatomic) id extra;
@end

@interface UrmsGroupBook : NSObject
@property (nonatomic) NSInteger groupId;
@property (nonatomic, copy) NSString *groupName;
@property (nonatomic, copy) NSString *adminId;
@property (nonatomic) id extra;
@end

@interface UrmsBookLicense : NSObject
@property (nonatomic) BOOL commonBookshelf;
@property (nonatomic, copy) NSString *ccid;
@property (nonatomic, copy) NSDate *expiry;
@property (nonatomic) UrmsContentStatus contentStatus;
@end

#endif
