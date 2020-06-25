//
//  AdobeDRMContainer.h
//  SimplyE
//
//  Created by Vladimir Fedorov on 13.05.2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

#ifndef AdobeDRMContainer_h
#define AdobeDRMContainer_h

#import <Foundation/Foundation.h>

@interface AdobeDRMContainer : NSObject
- (instancetype)init NS_UNAVAILABLE;
/// Inits DRM container for the file
/// @param fileURL file URL
- (instancetype)initWithURL:(NSURL *)fileURL;
/// Decrypt encrypted data
/// @param data Encrypted data
- (NSData *)decodeData:(NSData *)data;
@end

#endif /* AdobeDRMContainer_h */
