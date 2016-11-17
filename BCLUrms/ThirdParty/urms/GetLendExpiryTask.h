//
//  GetLendExpiryTask.h
//  urms-sdk-ios
//  Copyright (c) 2015 com.sonydadj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UrmsTask.h"

@interface UrmsGetLendExpiryResult : NSObject
@property (nonatomic, copy) NSArray*  books; // Array of UrmsBookLendExpiry*
@end

@interface UrmsGetLendExpiryTask : UrmsTask
- (id) init;

@property (nonatomic) Boolean containsCommonBookshelf;
@property (nonatomic, copy) NSArray*  ccids; // Array of NSString*

@property (nonatomic, readonly) UrmsGetLendExpiryResult* result;
@end
