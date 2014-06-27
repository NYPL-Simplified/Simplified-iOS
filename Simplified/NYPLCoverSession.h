@interface NYPLCoverSession : NSObject

+ (NYPLCoverSession *)sharedSession;

- (void)withURL:(NSURL *)url completionHandler:(void (^)(UIImage *image))handler;

- (UIImage *)cachedImageForURL:(NSURL *)url;

@end
