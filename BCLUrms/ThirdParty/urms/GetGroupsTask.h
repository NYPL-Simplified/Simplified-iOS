//
//  GetGroupsTask.h
//  urms-sdk-ios
//
//  Created by yano on 2015/05/11.
//
//

#import <Foundation/Foundation.h>
#import "UrmsTask.h"

@interface UrmsGetGroupsTask : UrmsTask
- (id) init;

@property (nonatomic, readonly, copy) NSArray* result; // Array of UrmsGroup*
@property (nonatomic) NSInteger groupId;
@property (nonatomic) UrmsGroupStatus groupStatus;
@end
