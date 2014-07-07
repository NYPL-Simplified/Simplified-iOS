@interface NYPLSession : NSObject

+ (instancetype)sharedSession;

- (void)withURL:(NSURL *)URL completionHandler:(void (^)(NSData *data))handler;

- (void)withURLs:(NSSet *)URLs handler:(void (^)(NSDictionary *URLToDataOrNull))handler;

- (NSData *)cachedDataForURL:(NSURL *)URL;

@end
