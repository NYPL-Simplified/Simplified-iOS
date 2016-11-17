//
//  AddGroupUserTask.h
//  urms-sdk-ios
//
//  Created by yano on 2015/05/12.
//
//

#import <Foundation/Foundation.h>
#import "UrmsTask.h"

@interface UrmsAddGroupUserTask : UrmsTask
- (void) addUserId:(NSString*)userId;
- (void) addUserIds:(NSArray*)userIds;

@property (nonatomic) NSInteger groupId;
@end
