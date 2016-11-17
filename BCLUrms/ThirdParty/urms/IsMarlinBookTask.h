//
//  IsMarlinBookTask.h
//  urms-sdk-ios
//
//  Copyright (c) 2015年 com.sonydadj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UrmsTask.h"

@interface UrmsIsMarlinBookTask : UrmsTask
@property (nonatomic, copy) NSString* filePath;

@property (nonatomic, assign) BOOL result;
@end
