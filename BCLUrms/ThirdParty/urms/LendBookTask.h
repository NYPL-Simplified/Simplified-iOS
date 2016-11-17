//
//  LendBookTask.h
//  cgp-sdk-ios
//
//  Created by yano on 2015/05/11.
//  Copyright (c) 2015年 com.sonydadj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UrmsTask.h"

@interface UrmsLendBookTask : UrmsTask
@property (nonatomic, copy) NSString* ccid;
@property (nonatomic, copy) NSString* borrowerId;
@property (nonatomic) NSInteger termSec;

- (void) setTermMin:(NSInteger)termMin;
- (void) setTermHour:(NSInteger)termHour;
- (void) setTermDay:(NSInteger)termDay;
@end
