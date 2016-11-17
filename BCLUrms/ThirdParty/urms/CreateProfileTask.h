//
//  RegisterUserTask.h
//  cgp-sdk-ios
//
//  Created by yano on 2015/05/09.
//  Copyright (c) 2015年 com.sonydadj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UrmsTask.h"

@interface UrmsProfileConfiguration : NSObject
@property (nonatomic, copy) NSString* cgpUrl;
@property (nonatomic, copy) NSString* marlinUrl;
@property (nonatomic, copy) NSString* marlinService;
@property (nonatomic, assign) BOOL useSSL;
@end


@interface UrmsCreateProfileTask : UrmsTask
@property (nonatomic, copy) NSString* authToken;
@property (nonatomic, copy) NSString* profileName;
@property (nonatomic, copy) NSString* deviceName;
@property (strong, nonatomic) UrmsProfileConfiguration* config;
@end
