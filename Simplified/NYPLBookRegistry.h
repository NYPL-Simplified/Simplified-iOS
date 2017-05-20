// This class encapsulates all access to book metadata and covers. All methods are thread-safe.

#import "NYPLBookState.h"

@class NYPLBook;
@class NYPLBookLocation;
@class NYPLReaderBookmarkElement;

// This is broadcast whenever the book registry is modified.
static NSString *const NYPLBookRegistryDidChangeNotification =
  @"NYPLBookRegistryDidChangeNotification";

static NSString *const NYPLBookProcessingDidChangeNotification =
  @"NYPLBookProcessingDidChangeNotification";

@interface NYPLBookRegistry : NSObject

// Returns all registered books.
@property (atomic, readonly) NSArray *allBooks;

// Returns all books that are on hold
@property (atomic, readonly) NSArray *heldBooks;

// Returns all books not on hold (borrowed or kept)
@property (atomic, readonly) NSArray *myBooks;

// Returns the number of books currently registered.
@property (atomic, readonly) NSUInteger count;

// Returns YES if the registry is currently syncing, else NO;
@property (atomic, readonly) BOOL syncing;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (NYPLBookRegistry *)sharedRegistry;

// Returns the URL of the directory used by the registry for storing content and metadata. The
// directory is not guaranteed to exist at the time this method is called.
- (NSURL *)registryDirectory;

// Saves the registry. This should be called before the application is terminated.
- (void)save;

- (void)justLoad;

// Syncs the latest content from the server. Attempts to sync while a sync is already in progress
// will simply be ignored. Resetting the registry while a sync is in progress will cause the handler
// not to be called.
- (void)syncWithCompletionHandler:(void (^)(BOOL success))handler;

// Calls syncWithCompletionHandler: with a handler that presents standard success/failure alerts on
// completion.
- (void)syncWithStandardAlertsOnCompletion;

// Adds a book to the book registry until it is manually removed. It allows the application to
// present information about obtained books when offline. Attempting to add a book already present
// will overwrite the existing book as if |updateBook:| were called. The location may be nil. The
// state provided must not be |NYPLBookStateUnregistered|.
- (void)addBook:(NYPLBook *)book
       location:(NYPLBookLocation *)location
          state:(NYPLBookState)state
  fulfillmentId:(NSString *)fulfillmentId
      bookmarks:(NSArray *)bookmarks;

// This method should be called whenever new book information is retrieved from a server. Doing so
// ensures that once the user has seen the new information, they will continue to do so when
// accessing the application off-line or when viewing books outside of the catalog. Attempts to
// update a book not already stored in the registry will simply be ignored, so it's reasonable to
// call this method whenever new information is obtained regardless of a given book's state.
- (void)updateBook:(NYPLBook *)book;

// This will update the book like updateBook does, but will also set its state to unregistered, then
// broadcast the change, then remove the book from the registry. This gives any views using the book
// a chance to update their copy with the new one, without having to keep it in the registry after.
- (void)updateAndRemoveBook:(NYPLBook *)book;

// This method should be called whenever new book information is retrieved from a server, but may
// not include user-specific information. We want to update the metadata, but not overwrite the
// existing availability information and acquisition URLs.
- (void)updateBookMetadata:(NYPLBook *)book;

// Returns the book for a given identifier if it is registered, else nil.
- (NYPLBook *)bookForIdentifier:(NSString *)identifier;

// Sets the state for a book previously registered given its identifier.
- (void)setState:(NYPLBookState)state forIdentifier:(NSString *)identifier;

// Returns the state of a book given its identifier.
- (NYPLBookState)stateForIdentifier:(NSString *)identifier;

// Sets the location for a book previously registered given its identifier.
- (void)setLocation:(NYPLBookLocation *)location forIdentifier:(NSString *)identifier;

// Returns the location of a book given its identifier.
- (NYPLBookLocation *)locationForIdentifier:(NSString *)identifier;

// Sets the fulfillmentId for a book previously registered given its identifier.
- (void)setFulfillmentId:(NSString *)fulfillmentId forIdentifier:(NSString *)identifier;

// Returns whether a book is processing something, given its identifier.
- (BOOL)processingForIdentifier:(NSString *)identifier;

// Sets the processing flag for a book previously registered given its identifier.
- (void)setProcessing:(BOOL)processing forIdentifier:(NSString *)identifier;

// Returns the fulfillmentId of a book given its identifier.
- (NSString *)fulfillmentIdForIdentifier:(NSString *)identifier;
    
// Returns the bookmarks for a book given its identifier
- (NSArray *)bookmarksForIdentifier:(NSString *)identifier;
  
// Add bookmark for a book given its identifier
- (void)addBookmark:(NYPLReaderBookmarkElement *)bookmark forIdentifier:(NSString *)identifier;
  
// Delete bookmark for a book given its identifer
- (void)deleteBookmark:(NYPLReaderBookmarkElement *)bookmark forIdentifier:(NSString *)identifier;

// replace bookmark for a book given its identifer
- (void)replaceBookmark:(NYPLReaderBookmarkElement *)oldElemennt with:(NYPLReaderBookmarkElement *)newElement forIdentifier:(NSString *)identifier;

// Given an identifier, this method removes a book from the registry. Attempting to remove a book
// that is not present will result in an error being logged.
- (void)removeBookForIdentifier:(NSString *)book;

// Returns the thumbnail for a book via a handler called on the main thread. The book does not have
// to be registered in order to retrieve a cover.
- (void)thumbnailImageForBook:(NYPLBook *)book
                      handler:(void (^)(UIImage *image))handler;

// Returns cover image if it exists, or falls back to thumbnail image load.
- (void)coverImageForBook:(NYPLBook *const)book
                  handler:(void (^)(UIImage *image))handler;

// The set passed in should contain NYPLBook objects. If |books| is nil or does not strictly contain
// NYPLBook objects, the handler will be called with nil. Otherwise, the dictionary passed to the
// handler maps book identifiers to images. The handler is always called on the main thread. The
// books do not have to be registered in order to retrieve covers.
- (void)thumbnailImagesForBooks:(NSSet *)books
                        handler:(void (^)(NSDictionary *bookIdentifiersToImages))handler;

// Immediately returns the cached thumbnail if available, else nil. Generated images are not
// returned. The book does not have to be registered in order to retrieve a cover.
- (UIImage *)cachedThumbnailImageForBook:(NYPLBook *)book;

// Resets the registry to an empty state.
- (void)reset;

// Resets the registry for a scpecific account
- (void)reset:(NSInteger)account;

// Delay committing any changes from a sync indefinitely.
- (void)delaySyncCommit;

// Stop delaying committing synced data.
- (void)stopDelaySyncCommit;

@end
