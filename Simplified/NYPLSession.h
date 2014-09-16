@interface NYPLSession : NSObject

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (NYPLSession *)sharedSession;

- (void)withURL:(NSURL *)URL completionHandler:(void (^)(NSData *data))handler;

- (void)withURLs:(NSSet *)URLs handler:(void (^)(NSDictionary *URLsToDataOrNull))handler;

- (NSData *)cachedDataForURL:(NSURL *)URL;

@end
