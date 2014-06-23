// This class provides convenience functions for retrieving remote data.

@interface NYPLAsyncData : NSObject

// |data| will be |nil| if an error occurred.
// The handler is guaranteed to be called on the main thread.
+ (void)withURL:(NSURL *)url
completionHandler:(void (^)(NSData *data))handler;

// The handler will be called with a dictionary containing all input URLs as keys.
// Each key will be associated with an NSData value if successful, else an NSNull value.
// The handler is guaranteed to be called on the main thread.
+ (void)withURLSet:(NSSet *)set
 completionHandler:(void (^)(NSDictionary *dataDictionary))handler;

@end
