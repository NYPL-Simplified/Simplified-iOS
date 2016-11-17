//
//  UrmsSdk.h
//  cgp-sdk-ios
//
//  Created by yano on 2015/05/07.
//  Copyright (c) 2015年 com.sonydadj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UrmsTypes.h"
#import "UrmsTask.h"

#import "GetOnlineBooksTask.h"
#import "GetDownloadedBooksTask.h"
#import "GetDownloadedBookTask.h"
#import "GetLendExpiryTask.h"
#import "EvaluateLicenseTask.h"
#import "RegisterBookTask.h"
#import "SynchronizeBookshelfTask.h"
#import "DeregisterBookTask.h"
#import "CreateBookmarkTask.h"
#import "DeleteBookmarkTask.h"
#import "UpdateBookmarkTask.h"
#import "GetBookmarksTask.h"
#import "LendBookTask.h"
#import "GiftBookTask.h"
#import "ReturnBookTask.h"
#import "GetbackBookTask.h"
#import "SellBookTask.h"
#import "CancelSellingTask.h"
#import "GetContentDetailTask.h"
#import "GetSettingsTask.h"
#import "CreateGroupTask.h"
#import "DeleteGroupTask.h"
#import "RenameGroupTask.h"
#import "GetGroupsTask.h"
#import "AddGroupUserTask.h"
#import "RemoveGroupUserTask.h"
#import "AddGroupBookTask.h"
#import "RemoveGroupBookTask.h"
#import "GetLinkTokenTask.h"
#import "LinkAccountsTask.h"
#import "UnLinkAccountTask.h"
#import "CreateProfileTask.h"
#import "SwitchProfileTask.h"
#import "GetActiveProfileTask.h"
#import "GetProfilesTask.h"
#import "DeleteProfileTask.h"
#import "IsMarlinBookTask.h"

typedef void (^UrmsSdkTaskModifierBlock)(UrmsTask *task);

@interface Urms : NSObject

+ (UrmsError*) initialize : (NSInteger)cgpApiTimeout
#if defined(TARGET_OS_IPHONE) && TARGET_OS_IPHONE
        keyChainServiceID : (NSString*)KeyChainServiceID
    keyChainVendorIDGroup : (NSString*)KeyChainVendorIDGroup
#endif
;

+ (Boolean) isInitialized;

+ (UrmsError*) shutdown;
+ (UrmsError*) reset;

+ (void) setTaskModifier:(UrmsSdkTaskModifierBlock)modifier;

+ (UrmsTaskExecutor*) getDefaultExecutor;
+ (UrmsTaskExecutor*) getBackgroundExecutor;

+ (Boolean) executeAsync:(UrmsTask*)task;
+ (Boolean) executeBackground:(UrmsTask*)task;

+ (UrmsCreateProfileTask*) createCreateProfileTask;
+ (UrmsSwitchProfileTask*) createSwitchProfileTask;
+ (UrmsGetActiveProfileTask*) createGetActiveProfileTask;
+ (UrmsGetProfilesTask*) createGetProfilesTask;
+ (UrmsDeleteProfileTask*) createDeleteProfileTask;

+ (UrmsGetOnlineBooksTask*) createGetOnlineBooksTask;
+ (UrmsGetDownloadedBooksTask*) createGetDownloadedBooksTask;
+ (UrmsGetDownloadedBookTask*) createGetDownloadedBookTask;
+ (UrmsGetDownloadedBookTask*) createGetDownloadedBookTask:(NSString*)ccid;
+ (UrmsGetLendExpiryTask*) createGetLendExpiryTask;

+ (UrmsEvaluateLicenseTask*) createEvaluateLicenseTask;
+ (UrmsEvaluateLicenseTask*) createEvaluateLicenseTask:(NSString*)ccid;

+ (UrmsRegisterBookTask*) createRegisterBookTask;
+ (UrmsRegisterBookTask*) createRegisterBookTask:(NSString*)ccid;

+ (UrmsSynchronizeBookshelfTask*) createSynchronizeBookshelfTask;

+ (UrmsDeregisterBookTask*) createDeregisterBookTask;
+ (UrmsDeregisterBookTask*) createDeregisterBookTask:(NSString*)ccid;

+ (UrmsIsMarlinBookTask*) createIsMarlinBookTask;
+ (UrmsIsMarlinBookTask*) createIsMarlinBookTask: (NSString*)filePath;

+ (UrmsCreateBookmarkTask*) createCreateBookmarkTask;

+ (UrmsUpdateBookmarkTask*) createUpdateBookmarkTask;

+ (UrmsDeleteBookmarkTask*) createDeleteBookmarkTask;
+ (UrmsDeleteBookmarkTask*) createDeleteBookmarkTask:(NSInteger)bookmarkId;

+ (UrmsGetBookmarksTask*) createGetBookmarksTask;
+ (UrmsGetBookmarksTask*) createGetBookmarksTask:(NSString*)ccid;

+ (UrmsLendBookTask*) createLendBookTask;
+ (UrmsLendBookTask*) createLendBookTask:(NSString*) ccid borrowerId:(NSString*)borrowerId;
+ (UrmsGiftBookTask*) createGiftBookTask;
+ (UrmsGiftBookTask*) createGiftBookTask:(NSString*) ccid recieverId:(NSString*)recieverId;
+ (UrmsReturnBookTask*) createReturnBookTask;
+ (UrmsReturnBookTask*) createReturnBookTask:(NSString*)ccid;
+ (UrmsGetbackBookTask*) createGetbackBookTask;
+ (UrmsGetbackBookTask*) createGetbackBookTask:(NSString*)ccid;

+ (UrmsSellBookTask*) createSellBookTask;
+ (UrmsSellBookTask*) createSellBookTask:(NSString*)ccid;
+ (UrmsCancelSellingTask*) createCancelSellingTask;
+ (UrmsCancelSellingTask*) createCancelSellingTask:(NSString*)ccid;

+ (UrmsGetContentDetailTask*) createGetContentDetailTask;
+ (UrmsGetContentDetailTask*) createGetContentDetailTask:(NSString*)ccid;
+ (UrmsGetSettingsTask*) createGetSettingsTask;

+ (UrmsCreateGroupTask*) createCreateGroupTask;
+ (UrmsCreateGroupTask*) createCreateGroupTask:(NSString*)groupName;
+ (UrmsDeleteGroupTask*) createDeleteGroupTask;
+ (UrmsDeleteGroupTask*) createDeleteGroupTask:(NSInteger)groupId;
+ (UrmsRenameGroupTask*) createRenameGroupTask;
+ (UrmsRenameGroupTask*) createRenameGroupTask:(NSInteger)groupId groupName:(NSString*)groupName;

+ (UrmsGetGroupsTask*) createGetGroupsTask;
+ (UrmsGetGroupsTask*) createGetGroupsTask:(NSInteger)groupId groupStatus:(UrmsGroupStatus)groupStatus;
+ (UrmsAddGroupUserTask*) createAddGroupUserTask;
+ (UrmsAddGroupUserTask*) createAddGroupUserTask:(NSInteger)groupId userIds:(NSArray*)userIds;
+ (UrmsRemoveGroupUserTask*) createRemoveGroupUserTask;
+ (UrmsRemoveGroupUserTask*) createRemoveGroupUserTask:(NSInteger)groupId userIds:(NSArray*)userIds;
+ (UrmsAddGroupBookTask*) createAddGroupBookTask;
+ (UrmsAddGroupBookTask*) createAddGroupBookTask:(NSInteger)groupId ccid:(NSString*)ccid;
+ (UrmsRemoveGroupBookTask*) createRemoveGroupBookTask;
+ (UrmsRemoveGroupBookTask*) createRemoveGroupBookTask:(NSInteger)groupId ccid:(NSString*)ccid;

+ (UrmsGetLinkTokenTask*) createGetLinkTokenTask;
+ (UrmsLinkAccountsTask*) createLinkAccountsTask:(NSString*)token;
+ (UrmsUnlinkAccountTask*) createUnlinkAccountTask;

@end
