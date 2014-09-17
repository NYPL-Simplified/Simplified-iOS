@class NYPLBook;

@interface NYPLMyBooksCoverRegistry : NSObject

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (NYPLMyBooksCoverRegistry *)sharedRegistry;

// All handlers are called on the main thread.

// |image| will be nil if a cover could not be obtained.
- (void)thumbnailImageForBook:(NYPLBook *)book
                      handler:(void (^)(UIImage *image))handler;

// The set passed in should contain NYPLBook objects. If |books| is nil or does not strictly contain
// NYPLBook objects, the handler will be called with nil. Otherwise, the dictionary passed to the
// handler maps book identifiers to images (or nulls in case of error).
- (void)thumbnailImagesForBooks:(NSSet *)books
                        handler:(void (^)(NSDictionary *bookIdentifersToImagesAndNulls))handler;

// Immediately returns the cached thumbnail if available, else nil.
- (UIImage *)cachedThumbnailImageForBook:(NYPLBook *)book;

// Pinned images will remain on-disk until they are manually unpinned. Only pinned images are
// guaranteed to be available when offline.
- (void)pinThumbnailImageForBook:(NYPLBook *)book;

- (void)removePinnedThumbnailImageForBookIdentfier:(NSString *)bookIdentifier;

- (void)removeAllPinnedThumbnailImages;

@end
