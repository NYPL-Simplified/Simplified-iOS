@class NYPLBook;

@interface NYPLMyBooksCoverRegistry : NSObject

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (NYPLMyBooksCoverRegistry *)sharedRegistry;

// All handlers are called on the main thread.

- (void)thumbnailImageForBook:(NYPLBook *)book
                      handler:(void (^)(UIImage *image))handler;

// The set passed in should contain NYPLBook objects. If |books| is nil or does not strictly contain
// NYPLBook objects, the handler will be called with nil. Otherwise, the dictionary passed to the
// handler maps book identifiers to images.
- (void)thumbnailImagesForBooks:(NSSet *)books
                        handler:(void (^)(NSDictionary *bookIdentifiersToImages))handler;

// Immediately returns the cached thumbnail if available, else nil. Generated images are not
// returned.
- (UIImage *)cachedThumbnailImageForBook:(NYPLBook *)book;

// Pinned images will remain on-disk until they are manually unpinned. Only pinned images are
// guaranteed to be available when offline.
- (void)pinThumbnailImageForBook:(NYPLBook *)book;

- (void)removePinnedThumbnailImageForBookIdentifier:(NSString *)bookIdentifier;

- (void)removeAllPinnedThumbnailImages;

@end
