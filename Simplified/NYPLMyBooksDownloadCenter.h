@class NYPLBook;

static NSString *const NYPLMyBooksDownloadCenterDidChangeNotification =
  @"NYPLMyBooksDownloadCenterDidChangeNotification";

@interface NYPLMyBooksDownloadCenter : NSObject

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (NYPLMyBooksDownloadCenter *)sharedDownloadCenter;

// This method will request credentials from the user if necessary.
- (void)startDownloadForBook:(NYPLBook *)book;
- (void)startDownloadForPreloadedBook:(NYPLBook *)book;

// This works for both failed downloads (to reset their state) and for downloads in progress.
- (void)cancelDownloadForBookIdentifier:(NSString *)identifier;

// Removes local content and removes the book from the registry, after presenting a confirmation dialog.
- (void)removeCompletedDownloadForBookIdentifier:(NSString *)identifier;

// Deletes the downloaded book, but doesn't touch the registry.
- (void)deleteLocalContentForBookIdentifier:(NSString *)identifier;

// Deletes all local content and silently cancels downloads, but does NOT touch the registry.
- (void)reset;

// The value returned is in the range [0.0, 1.0].
- (double)downloadProgressForBookIdentifier:(NSString *)bookIdentifier;

// This returns a URL even if the book is not on-disk.
- (NSURL *)fileURLForBookIndentifier:(NSString *)identifier;

@end
