@class NYPLBook;

@interface NYPLBookCoverRegistry : NSObject

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (NYPLBookCoverRegistry *)sharedRegistry;

// NOTE: Handlers are *not* called on the main thread.

// |image| will be nil if a cover could not be obtained.
- (void)temporaryThumbnailImageForBook:(NYPLBook *)book handler:(void (^)(UIImage *image))handler;

@end
