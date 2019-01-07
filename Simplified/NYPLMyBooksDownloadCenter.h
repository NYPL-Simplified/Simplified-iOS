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

// This method will immediately perform a checkout (borrow link fulfillment) and
// full download, and will inform 'early' when just the borrow portion has
// completed. This method should ONLY be used for checkouts when the app is in a
// background state. Failures can be recovered by the user at a later time if
// necessary.
- (void)startBorrowAndDownload:(NYPLBook *)book borrowCompletion:(void (^)(void))borrowCompletion;

// This works for both failed downloads (to reset their state) and for downloads in progress.
- (void)cancelDownloadForBookIdentifier:(NSString *)identifier;

// Removes local content and removes the book from the registry, after presenting a confirmation dialog.
- (void)removeCompletedDownloadForBookIdentifier:(NSString *)identifier;

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
- (void)deleteLocalContentForBookIdentifier:(NSString *const)identifier account:(NSInteger const)account;

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
