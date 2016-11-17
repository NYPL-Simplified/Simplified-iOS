//
//  RegisterBookTask.h
//  cgp-sdk-ios
//
//  Created by yano on 2015/05/09.
//  Copyright (c) 2015年 com.sonydadj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UrmsTask.h"

@interface UrmsRegisterBookDownloadContext : NSObject
- (id) init;
@property (nonatomic, copy) NSString* source;
@property (nonatomic, copy) NSString* destination;
@property (nonatomic) Boolean shouldDownload;
@end

typedef void (^UrmsTaskPreDownloadCallbackBlock)(id task, UrmsRegisterBookDownloadContext *context);
typedef void (^UrmsTaskProgressCallbackBlock)(id task, NSInteger current, NSInteger total);

@interface UrmsRegisterBookTask : UrmsTask <NSURLConnectionDataDelegate>
@property (nonatomic, copy) NSString* ccid;
@property (nonatomic) NSInteger timeoutMillis;
@property (nonatomic, copy) NSString* destination;
@property (nonatomic, copy) NSString* downloadSource;
@property (nonatomic, copy) UrmsTaskProgressCallbackBlock onProgress;
@property (nonatomic, copy) UrmsTaskPreDownloadCallbackBlock onPreDownload;
@end
