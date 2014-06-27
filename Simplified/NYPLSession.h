@interface NYPLSession : NSObject

+ (NYPLSession *)sharedSession;

- (void)withURL:(NSURL *)url completionHandler:(void (^)(NSData *data))handler;

- (void)withURLs:(NSSet *)urls handler:(void (^)(NSDictionary *dataDictionary))handler;

- (NSData *)cachedDataForURL:(NSURL *)url;

@end
