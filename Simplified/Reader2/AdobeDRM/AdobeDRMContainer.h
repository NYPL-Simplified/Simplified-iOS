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
NS_ASSUME_NONNULL_BEGIN
- (instancetype)init NS_UNAVAILABLE;
/// Inits DRM container for the file
/// @param fileURL file URL
/// @param encryptionData encryption.xml data
- (instancetype)initWithURL:(NSURL *)fileURL encryptionData: (NSData *)encryptionData;
/// Decrypt encrypted data
/// @param data Encrypted data
- (NSData *)decodeData:(NSData *)data;
/// Decrypt encrypted data for file ar path inside ePub file
/// @param data Encrypted data
/// @param path File path inside ePub file
- (NSData *)decodeData:(NSData *)data at:(NSString *)path;
NS_ASSUME_NONNULL_END
/// Error messages from the container or underlying classes
@property (nonatomic, strong) NSString * _Nullable epubDecodingError;
@end

#endif /* AdobeDRMContainer_h */
