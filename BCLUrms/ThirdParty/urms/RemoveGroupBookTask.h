//
//  RemoveGroupBookTask.h
//  urms-sdk-ios
//
//  Created by yano on 2015/05/12.
//
//

#import <Foundation/Foundation.h>
#import "UrmsTask.h"

@interface UrmsRemoveGroupBookTask : UrmsTask
@property (nonatomic) NSInteger groupId;
@property (nonatomic, copy) NSString* ccid;
@end
