#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wauto-import"

#import <Foundation/Foundation.h>

#pragma clang diagnostic pop

@class NYPLAdeptConnector;

@protocol NYPLAdeptConnectorDelegate

- (void)adeptConnector:(NYPLAdeptConnector *)adeptConnector
didFinishDownloadingToURL:(NSURL *)URL
            rightsData:(NSData *)rightsData
                   tag:(NSString *)tag;

- (void)adeptConnector:(NYPLAdeptConnector *)adeptConnector
     didUpdateProgress:(double)progress
                   tag:(NSString *)tag;

@end

@interface NYPLAdeptConnector : NSObject

@property (atomic, weak) id<NYPLAdeptConnectorDelegate> delegate;
@property (atomic, readonly) BOOL deviceAuthorized;

+ (NYPLAdeptConnector *)sharedAdeptConnector;

- (void)authorizeWithVendorID:(NSString *)vendorID
                     username:(NSString *)username
                     password:(NSString *)password;

- (void)deauthorize;

- (void)fulfillWithACSMData:(NSData *)ACSMData tag:(NSString *)tag;

@end
