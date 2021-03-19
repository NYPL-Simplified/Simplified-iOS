// This class is intended for internal use by NYPLBookRegistry only.

@class NYPLBook;

@interface NYPLBookCoverRegistry : NSObject

// All handlers are called on the main thread.

- (void)thumbnailImageForBook:(NYPLBook *)book
                      handler:(void (^)(UIImage *image))handler;

- (void)coverImageForBook:(NYPLBook *)book
                  handler:(void (^)(UIImage *image))handler;

// The set passed in must contain NYPLBook objects. The dictionary passed to the handler maps book
// identifiers to images.
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
