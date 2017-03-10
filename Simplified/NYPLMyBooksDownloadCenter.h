@class NYPLBook;
@class NYPLMyBooksDownloadInfo;

static NSString *const NYPLMyBooksDownloadCenterDidChangeNotification =
  @"NYPLMyBooksDownloadCenterDidChangeNotification";

@interface NYPLMyBooksDownloadCenter : NSObject

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (NYPLMyBooksDownloadCenter *)sharedDownloadCenter;

// This method will request credentials from the user if necessary.
- (void)startDownloadForBook:(NYPLBook *)book;

// This works for both failed downloads (to reset their state) and for downloads in progress.
- (void)cancelDownloadForBookIdentifier:(NSString *)identifier;

// Removes local content and removes the book from the registry, after presenting a confirmation dialog.
- (void)removeCompletedDownloadForBookIdentifier:(NSString *)identifier;

// Deletes the downloaded book, but doesn't touch the registry.
- (void)deleteLocalContentForBookIdentifier:(NSString *)identifier;

// Returns a borrowed book, cancels a held book, or "returns" a kept book.
- (void)returnBookWithIdentifier:(NSString *)identifier;

// Deletes all local content and silently cancels downloads, but does NOT touch the registry.
- (void)reset;

// Deletes all local content for a specific account
- (void)reset:(NSInteger)account;

// The value returned is in the range [0.0, 1.0].
- (double)downloadProgressForBookIdentifier:(NSString *)bookIdentifier;

// Useful to get the DRM type, to see whether the download has gotten to the stage where that's known
- (NYPLMyBooksDownloadInfo *)downloadInfoForBookIdentifier:(NSString *)bookIdentifier;

// This returns a URL even if the book is not on-disk. Returns nil if |identifier| is nil.
- (NSURL *)fileURLForBookIndentifier:(NSString *)identifier;

@end
