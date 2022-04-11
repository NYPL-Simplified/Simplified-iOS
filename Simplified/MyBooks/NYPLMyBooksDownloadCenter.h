@class NYPLBook;
@class NYPLMyBooksDownloadInfo;

@interface NYPLMyBooksDownloadCenter : NSObject

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (NYPLMyBooksDownloadCenter *)sharedDownloadCenter;

// This method will request credentials from the user if necessary.
- (void)startDownloadForBook:(NYPLBook *)book;

// This method will immediately perform a checkout (borrow link and/or adobe
// fulfillment), and then optionally begin to download the book. A handler is
// called at the completion of the borrow portion, so that if the app is in a
// background state (like during a Notification Action), it can suppress
// UIAlerts or other behavior requiring an Active State.
- (void)startBorrowForBook:(NYPLBook *)book attemptDownload:(BOOL)shouldAttemptDownload borrowCompletion:(void (^)(void))borrowCompletion;

// This works for both failed downloads (to reset their state) and for downloads in progress.
- (void)cancelDownloadForBookIdentifier:(NSString *)identifier;

// Deletes the downloaded book, but doesn't touch the registry. The book should still be in the
// registry when this is called.
- (void)deleteLocalContentForBookIdentifier:(NSString *)identifier;

/// Deletes local content for the specified book @c identifier and @c account. This method should be used with care:
/// @c deleteLocalContentForBookIdentifier: should be preferred whenever possible.
/// @warning The registry must currently have data loaded for @c account either in the standard manner or via
///          @c -[NYPLBookRegistry @c performWithAccount:block:].
/// @warning The book should still be in the registry when this is called.
/// @param identifier The identifier of the book whose content should be deleted.
/// @param account    The id of the account within which a book identified by @c identifier resides.
- (void)deleteLocalContentForBookIdentifier:(NSString *const)identifier account:(NSString *const)account;

// Returns a borrowed book, cancels a held book, or "returns" a kept book.
- (void)returnBookWithIdentifier:(NSString *)identifier;

// Deletes all local content and silently cancels downloads, but does NOT touch the registry.
- (void)reset;

// Deletes all local content for a specific account
- (void)reset:(NSString *)account;

// The value returned is in the range [0.0, 1.0].
- (double)downloadProgressForBookIdentifier:(NSString *)bookIdentifier;

// Useful to get the DRM type, to see whether the download has gotten to the stage where that's known
- (NYPLMyBooksDownloadInfo *)downloadInfoForBookIdentifier:(NSString *)bookIdentifier;

// This returns a URL even if the book is not on-disk. Returns nil if |identifier| is nil.
- (NSURL *)fileURLForBookIndentifier:(NSString *)identifier;

#if FEATURE_AUDIOBOOKS
- (id)audiobookManagerForBookID:(NSString *)bookID;

- (void)downloadProgressDidUpdateTo:(double)progress forBookIdentifier:(NSString *)bookID;
#endif

@end
