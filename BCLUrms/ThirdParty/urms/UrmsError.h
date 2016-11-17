//
//  UrmsError.h
//  cgp-sdk-ios
//
//  Created by yano on 2015/05/07.
//  Copyright (c) 2015年 com.sonydadj. All rights reserved.
//


#ifndef _URMS_ERROR_H
#define _URMS_ERROR_H

#import <Foundation/Foundation.h>


typedef enum _urms_error_type
{
    UrmsErrMask = 0x00007FFF,
    UrmsSuccess	= 0x00000000,
    UrmsOutdatedVersion = 0x00000001,
    UrmsNotInitialized = 0x00000002,
    UrmsExpiredSdk = 0x00000008,
    UrmsCanceled    = 0x00000009,
    UrmsGeneralError    = 0x00000011,
    UrmsInvalidParameter = 0x00000012,
    UrmsNetworkError    = 0x00000019,
    UrmsNetworkTimeout  = 0x0000001A,
    UrmsServerDown  = 0x0000001B,
    UrmsServerMaintenance   = 0x0000001C,
    UrmsSystemError = 0x00000021,
    UrmsOutOfMemory = 0x00000029,
    UrmsNotReadable = 0x00000031,
    UrmsInvalidLicense  = 0x00000032,
    UrmsRegisterDeviceFailed    = 0x00000039,
    UrmsRegisterUserFailed  = 0x0000003A,
    UrmsRegisterUserDeviceCapacityReached   = 0x0000003B,
    UrmsNotOperatable   = 0x00000041,
    UrmsNotOwn  = 0x00000042,
    UrmsNotBorrowing    = 0x00000043,
    UrmsNotLending  = 0x00000044,
    UrmsNotSelling  = 0x00000045,
    UrmsNoBook  = 0x00000061,
    UrmsNoUser  = 0x00000062,
    UrmsNoGroup = 0x00000063,
    UrmsNoBookmark  = 0x00000064,
    UrmsAlreadyOwn  = 0x0000006A,
    UrmsAlreadyExist = 0x0000006B,
    UrmsInvalidVersion  = 0x00000071,
    UrmsNotRegistered   = 0x00000072,
    UrmsNotAuthorized   = 0x00000073,
    UrmsLooseTime   = 0x00000074,
    UrmsNotPermitted = 0x00000075,
    UrmsFileBroken  = 0x00000077,
    UrmsInvalidToken = 0x00000078,
    UrmsAlreadyConnected= 0x00000079,
    UrmsTooManyAccounts = 0x0000007A,
    UrmsNotConnected = 0x0000007B,
    UrmsCannotConnectedToSelf = 0x0000007C,
    UrmsInvalidCounter  = 0x0000007D,
    UrmsFileIOError  = 0x00000080,
} UrmsErrorType;

typedef enum _urms_api_type : unsigned int
{
    UrmsApiMask = 0xFF000000,
    UrmsApiNone = 0,
    UrmsApiInitialize = 0x01000000,
    UrmsApiRegisterUser = 0x02000000,
    UrmsApiDeregisterUser = 0x03000000,
    UrmsApiConfigureBookshelf = 0x04000000,
    UrmsApiGetSettings = 0x05000000,
//    UrmsApiGetApplicationGroup = 0x06000000,
    UrmsApiCheckSignature	= 0x07000000,
    UrmsApiGetOnlineBooks = 0x10000000,
    UrmsApiGetDownloadedBooks = 0x11000000,
    UrmsApiSynchronizeBookshelf = 0x12000000,
    UrmsApiGetContentDetail = 0x13000000,
    UrmsApiGetCopyAndPrint = 0x14000000,
    UrmsApiGetLendExpiry = 0x15000000,
    UrmsApiRegisterBook = 0x18000000,
    UrmsApiDeregisterBook = 0x19000000,
    UrmsApiEvaluateLicense = 0x1A000000,
    UrmsApiPrepareRegisterBook = 0x1B000000,
    UrmsApiExecuteRegisterBook = 0x1C000000,
    UrmsApiInvalidateBook = 0x1D000000,
    UrmsApiIsMarlinBook	= 0x1E000000,
    UrmsApiGetBookmarks = 0x20000000,
    UrmsApiCreateBookmark = 0x21000000,
    UrmsApiDeleteBookmark = 0x22000000,
    UrmsApiLendBook = 0x28000000,
    UrmsApiReturnBook = 0x29000000,
    UrmsApiGetbackBook = 0x2A000000,
    UrmsApiGiftBook = 0x2B000000,
    UrmsApiSellBook = 0x2C000000,
    UrmsApiCancelSelling = 0x2D000000,
    UrmsApiGetGroup = 0x30000000,
    UrmsApiRenameGroup = 0x31000000,
    UrmsApiCreateGroup = 0x32000000,
    UrmsApiDeleteGroup = 0x33000000,
    UrmsApiAddGroupUser = 0x34000000,
    UrmsApiRemoveGroupUser = 0x35000000,
    UrmsApiAddGroupBook = 0x36000000,
    UrmsApiRemoveGroupBook = 0x37000000,
    UrmsApiGetLinkToken = 0x38000000,
    UrmsApiLinkAccounts = 0x39000000,
    UrmsApiUnLinkAccounts = 0x3A000000,
    UrmsApiCreateProfile = 0x3B000000,
    UrmsApiGetActiveProfile = 0x3C000000,
    UrmsApiGetProfiles = 0x3D000000,
    UrmsApiSwitchProfile = 0x3B000000,
} UrmsApiType;

@interface UrmsError : NSObject
- (Boolean) isError;
- (Boolean) isErrorExceptNetwork;
- (id) init:(UrmsErrorType) errorType urmsError:(NSInteger)urmsError internalError:(NSInteger) internalError;
- (id) initWithError:(UrmsApiType) api errorType:(UrmsErrorType) errorType;

@property (nonatomic, readonly)       UrmsErrorType errorType;
@property (nonatomic, readonly)       UrmsApiType   api;
@property (nonatomic, readonly, copy) NSString      *errorCode;
@end

#endif