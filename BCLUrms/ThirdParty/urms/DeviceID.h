//
//  DeviceID.h
//  urms-sdk-ios
//
//  Created by František Bureš on 23/03/15.
//  Copyright (c) 2015 Denuvo. All rights reserved.
//

#ifndef urms_sdk_ios_DeviceID_h
#define urms_sdk_ios_DeviceID_h

#import <Foundation/Foundation.h>

@interface DeviceID : NSObject
{
    NSString *kKeyChainVendorIDGroup;
    NSString *kKeyChainServiceID;
//    NSString *kKeyChainVendorIDAccessGroup;
}
- (id) init: (NSString*)KeyChainServiceID KeyChainVendorIDGroup : (NSString*)KeyChainVendorIDGroup; // KeyChainVendorIDAccessGroup : (NSString*)KeyChainVendorIDAccessGroup;
-(NSString *)getPersistentIdentifier;

@property (strong) NSString *kKeyChainVendorIDGroup;
@property (strong) NSString *kKeyChainServiceID;
//@property (strong) NSString *kKeyChainVendorIDAccessGroup;

@end

#endif
