//
//  GetCopyAndPrintTask.h
//  urms-sdk-ios
//
//  Created by yano on 2015/05/11.
//
//

#import <Foundation/Foundation.h>
#import "UrmsTask.h"

@interface UrmsGetDownloadedBookTask : UrmsTask
@property (nonatomic, readonly) UrmsDownloadedBook* result;
@property (nonatomic, copy) NSString* ccid;
@end
