//
//  RenameGroupTask.h
//  urms-sdk-ios
//
//  Created by yano on 2015/05/11.
//
//

#import <Foundation/Foundation.h>
#import "UrmsTask.h"

@interface UrmsRenameGroupTask : UrmsTask
@property (nonatomic) NSInteger groupId;
@property (nonatomic, copy) NSString* groupName;
@end
