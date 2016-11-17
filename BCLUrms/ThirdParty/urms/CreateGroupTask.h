//
//  CreateGroupTask.h
//  urms-sdk-ios
//
//  Created by yano on 2015/05/11.
//
//

#import <Foundation/Foundation.h>
#import "UrmsTask.h"


@interface UrmsCreateGroupTask : UrmsTask
@property (nonatomic, readonly) NSInteger result;
@property (nonatomic, copy) NSString* groupName;
@end
