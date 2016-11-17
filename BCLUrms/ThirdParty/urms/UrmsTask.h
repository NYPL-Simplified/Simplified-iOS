//
//  UrmsTaskExecutor.h
//  cgp-sdk-ios
//
//  Created by yano on 2015/05/07.
//  Copyright (c) 2015年 com.sonydadj. All rights reserved.
//

#ifndef _URMS_TASK_H
#define _URMS_TASK_H

#import <Foundation/Foundation.h>
#import "UrmsTypes.h"
#import "UrmsError.h"

typedef void (^UrmsTaskCallbackBlock)(id task);
typedef void (^UrmsTaskErrorCallbackBlock)(id task, UrmsError *error);

@protocol UrmsTaskCallback <NSObject>
@optional
- (void) onTaskPreExecute:(id)task;
- (void) onTaskPostExecute:(id)task;
- (void) onTaskCancelled:(id)task;
- (void) onTaskSucceeded:(id)task;
- (void) onTaskFailed:(id)task error:(UrmsError*)error;
@end


@interface UrmsDispatcher : NSObject
- (id) init;
- (void) dispatch: (dispatch_block_t)block;
@end

@interface UrmsTask : NSObject
- (id) init;
- (Boolean) isError;
- (Boolean) isCancelled;
- (UrmsTask*) cancel;
- (Boolean) validateParameters:(UrmsDispatcher*)dispatcher;
- (Boolean) executeWithDispatcher:(UrmsDispatcher*)dispatcher;
- (Boolean) execute;
- (Boolean) execute:(Boolean)shouldCallback;
- (Boolean) executeAsync;

- (void) doPreExecuteCallback;
- (void) doPostExecuteCallback;
- (void) doSucceededCallback;
- (void) doCancelledCallback;
- (void) doFailedCallback;
- (void) dispatch:(dispatch_block_t)block;

- (UrmsError*) doExecute;
- (NSString*) doValidateParameters;
- (UrmsApiType) getApiType;

@property (nonatomic, readonly) UrmsTaskStatus status;
@property (nonatomic, readonly) UrmsError      *error;

@property (nonatomic, weak) id<UrmsTaskCallback> delegate;
@property (nonatomic, copy) UrmsTaskCallbackBlock onPreExecute;
@property (nonatomic, copy) UrmsTaskCallbackBlock onPostExecute;
@property (nonatomic, copy) UrmsTaskCallbackBlock onCancelled;
@property (nonatomic, copy) UrmsTaskCallbackBlock onSucceeded;
@property (nonatomic, copy) UrmsTaskErrorCallbackBlock onFailed;
@property (nonatomic) id extra;
@end


@interface UrmsTaskExecutor : UrmsDispatcher
- (id) init;
- (Boolean) enqueue : (UrmsTask*) task;
@end

#endif
