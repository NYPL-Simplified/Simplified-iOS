//
//  GetSettingsTask.h
//  urms-sdk-ios
//
//  Created by yano on 2015/05/11.
//
//

#import <Foundation/Foundation.h>
#import "UrmsTask.h"

@interface UrmsGetSettingsResult : NSObject
@property (nonatomic, copy) NSString* storeName;
@property (nonatomic, copy) NSString* deviceName;
@property (nonatomic) Boolean commonBookshelfStatus;
@end

@interface UrmsGetSettingsTask : UrmsTask
@property (nonatomic, readonly) UrmsGetSettingsResult* result;
@end
