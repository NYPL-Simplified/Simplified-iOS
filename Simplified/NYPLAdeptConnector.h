#import <Foundation/Foundation.h>

@interface NYPLAdeptConnector : NSObject

@property (atomic, readonly) BOOL isDeviceAuthorized;

+ (NYPLAdeptConnector *)sharedAdeptConnector;

@end
