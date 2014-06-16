// This class provides convenience functions for retrieving remote data.

@import Foundation;

@interface NYPLAsyncData : NSObject

// |data| will be |nil| if an error occurred.
// The handler is guaranteed to be called on the main thread.
+ (void)withURL:(NSURL *)url
completionHandler:(void (^)(NSData *data))handler;

@end
