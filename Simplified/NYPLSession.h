@interface NYPLSession : NSObject

+ (NYPLSession *)sharedSession;

- (void)withURL:(NSURL *)url completionHandler:(void (^)(NSData *data))handler;

- (NSData *)cachedDataForURL:(NSURL *)url;

@end
