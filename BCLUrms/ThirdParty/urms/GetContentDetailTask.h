//
//  GetContentDetailTask.h
//  urms-sdk-ios
//
//  Created by yano on 2015/05/11.
//
//

#import <Foundation/Foundation.h>
#import "UrmsTask.h"

@interface UrmsGetContentDetailResult : NSObject
@property (nonatomic) UrmsOwnBook* ownBook;
@property (nonatomic, copy) NSArray* commonBookshelfBooks; // Array of UrmsCommonBookshelfBook*
@property (nonatomic, copy) NSArray* groupBooks; // Array of UrmsGroupBook*
@end


@interface UrmsGetContentDetailTask : UrmsTask
@property (nonatomic, readonly) UrmsGetContentDetailResult* result;
@property (nonatomic, copy) NSString* ccid;
@end
