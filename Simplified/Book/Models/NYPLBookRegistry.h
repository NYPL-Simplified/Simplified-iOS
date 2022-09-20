// This class encapsulates all access to book metadata and covers. All methods are thread-safe.

@class NYPLBook;
@class NYPLBookLocation;
@class NYPLReadiumBookmark;
@class NYPLAudiobookBookmark;
@protocol NYPLAudiobookRegistryProvider;

typedef NS_ENUM(NSInteger, NYPLBookState);

@protocol NYPLBookRegistryProvider <NSObject>

- (nonnull NSArray<NYPLReadiumBookmark *> *)readiumBookmarksForIdentifier:(nonnull NSString *)identifier;

- (void)setLocation:(nullable NYPLBookLocation *)location
      forIdentifier:(nonnull NSString *)identifier;

- (nullable NYPLBookLocation *)locationForIdentifier:(nonnull NSString *)identifier;

- (void)addReadiumBookmark:(nonnull NYPLReadiumBookmark *)bookmark
             forIdentifier:(nonnull NSString *)identifier;
  
- (void)deleteReadiumBookmark:(nonnull NYPLReadiumBookmark *)bookmark
                forIdentifier:(nonnull NSString *)identifier;

- (void)replaceBookmark:(nonnull NYPLReadiumBookmark *)oldBookmark
                   with:(nonnull NYPLReadiumBookmark *)newBookmark
          forIdentifier:(nonnull NSString *)identifier;

@end

@interface NYPLBookRegistry : NSObject <NYPLBookRegistryProvider>

// Returns all registered books.
@property (atomic, readonly, nonnull) NSArray *allBooks;

// Returns all books that are on hold
@property (atomic, readonly, nonnull) NSArray *heldBooks;

// Returns all books not on hold (borrowed or kept)
@property (atomic, readonly, nonnull) NSArray *myBooks;

// Returns the number of books currently registered.
@property (atomic, readonly) NSUInteger count;

// Returns YES if the registry is currently syncing, else NO;
@property (atomic, readonly) BOOL syncing;

+ (nonnull id)new NS_UNAVAILABLE;
- (nonnull id)init NS_UNAVAILABLE;

+ (nonnull NYPLBookRegistry *)sharedRegistry;

// Returns the URL of the directory used by the registry for storing content and metadata. The
// directory is not guaranteed to exist at the time this method is called.
- (nullable NSURL *)registryDirectory;

/**
 Saves the registry to disk. This should be called before the application
 is terminated.
 */
- (void)save;

/**
 Loads the registry from disk.
 */
- (void)justLoad;

/**
 Grandfathering original sync method. Passes nil for the background fetch handler.

 @param shouldResetCache Whether we should wipe the whole cache of
 loans/holds/book details/open search/ungrouped feeds in its entirety or not.
 @param handler Completion Handler is on main thread, but not gauranteed to be called.
 */
- (void)syncResettingCache:(BOOL)shouldResetCache
         completionHandler:(void (^ _Nullable)(NSDictionary * _Nullable errorDict))handler;

/**
 Syncs the latest loans content from the server. Attempting to sync while one is
 already in progress will be ignored. Resetting the registry while a sync is in
 progress will cause the handler not to be called.

 Errors are logged via NYPLErrorLogger.

 @param shouldResetCache Whether we should wipe the whole cache of
 loans/holds/book details/open search/ungrouped feeds in its entirety or not.
 @param handler Called on completion on the main thread. Not guaranteed to be
 called.
 @param fetchHandler Called on completion on the main thread while exceuting
 from a Background App State, like from the App Delegate method. Calls to this
 block should be balanced with calls to the method.
 */
- (void)syncResettingCache:(BOOL)shouldResetCache
         completionHandler:(void (^ _Nullable)(NSDictionary * _Nullable errorDict))handler
    backgroundFetchHandler:(void (^ _Nullable)(UIBackgroundFetchResult))fetchHandler;

/**
 Calls syncWithCompletionHandler: with a handler that presents standard
 success/failure alerts on completion.
 */
- (void)syncWithStandardAlertsOnCompletion;

// Adds a book to the book registry until it is manually removed. It allows the application to
// present information about obtained books when offline. Attempting to add a book already present
// will overwrite the existing book as if |updateBook:| were called. The location may be nil. The
// state provided must be one of NYPLBookState and must not be |NYPLBookStateUnregistered|.
// TODO: Use NYPLBookState instead of NSInteger when migrate to Swift
// Note: The object type of the audiobook bookmarks array is not specified
// because using a forward declaration class in the function signature
// will cause the function not being accessible from Swift.
// To avoid error, we perform a check on the object type in the body of the function.
- (void)addBook:(nonnull NYPLBook *)book
       location:(nullable NYPLBookLocation *)location
          state:(NSInteger)state
  fulfillmentId:(nullable NSString *)fulfillmentId
readiumBookmarks:(nullable NSArray<NYPLReadiumBookmark *> *)readiumBookmarks
audiobookBookmarks:(nullable NSArray *)audiobookBookmarks
genericBookmarks:(nullable NSArray<NYPLBookLocation *> *)genericBookmarks;

// This method should be called whenever new book information is retrieved from a server. Doing so
// ensures that once the user has seen the new information, they will continue to do so when
// accessing the application off-line or when viewing books outside of the catalog. Attempts to
// update a book not already stored in the registry will simply be ignored, so it's reasonable to
// call this method whenever new information is obtained regardless of a given book's state.
- (void)updateBook:(nonnull NYPLBook *)book;

// This will update the book like updateBook does, but will also set its state to unregistered, then
// broadcast the change, then remove the book from the registry. This gives any views using the book
// a chance to update their copy with the new one, without having to keep it in the registry after.
- (void)updateAndRemoveBook:(nonnull NYPLBook *)book;

/// Returns the given book after updating its metadata.
/// @note This method should be called whenever new book information is retrieved from a server, but may
///  not include user-specific information. We want to update the metadata, but not overwrite the existing
///  availability information and acquisition URLs.
/// @param book The book we want to update
- (nullable NYPLBook *)updatedBookMetadata:(nonnull NYPLBook *)book;

// Returns the book for a given identifier if it is registered, else nil.
- (nullable NYPLBook *)bookForIdentifier:(nonnull NSString *)identifier;

// Sets the state for a book previously registered given its identifier.
- (void)setState:(NYPLBookState)state forIdentifier:(nonnull NSString *)identifier;

// For Swift, since setState method above is not being compiled into the bridging header
// possibly due to the enum NYPLBookState is being declared in both Swift and ObjC
// stateCode should always be one of NYPLBookState cases
// TODO: Remove when migrate to Swift, use setState:forIdentifier: instead
- (void)setStateWithCode:(NSInteger)stateCode forIdentifier:(nonnull NSString *)identifier;

// Reset the book state for the given book identifier to NYPLBookStateDownloadNeeded
// for books that were in a downloaded/downloading states.
- (void)resetStateToDownloadNeededForIdentifier:(nonnull NSString *)identifier;

// Returns the state of a book given its identifier.
- (NYPLBookState)stateForIdentifier:(nonnull NSString *)identifier;

// For Swift, since stateForIdentifier method above is not being compiled into the bridging header
// possibly due to the enum NYPLBookState is being declared in both Swift and ObjC
// stateCode should always be one of NYPLBookState cases
// TODO: Remove when migrate to Swift, use stateForIdentifier: instead
- (NSInteger)stateRawValueForIdentifier:(nonnull NSString *)identifier;

// Sets the location for a book previously registered given its identifier.
- (void)setLocation:(nullable NYPLBookLocation *)location
      forIdentifier:(nonnull NSString *)identifier;

// Returns the location of a book given its identifier.
- (nullable NYPLBookLocation *)locationForIdentifier:(nonnull NSString *)identifier;

// Sets the fulfillmentId for a book previously registered given its identifier.
- (void)setFulfillmentId:(nullable NSString *)fulfillmentId forIdentifier:(nonnull NSString *)identifier;

// Returns whether a book is processing something, given its identifier.
- (BOOL)processingForIdentifier:(nonnull NSString *)identifier;

// Sets the processing flag for a book previously registered given its identifier.
- (void)setProcessing:(BOOL)processing forIdentifier:(nonnull NSString *)identifier;

// Returns the fulfillmentId of a book given its identifier.
- (nullable NSString *)fulfillmentIdForIdentifier:(nonnull NSString *)identifier;
    
// Returns the readium bookmarks for a book given its identifier
- (nonnull NSArray<NYPLReadiumBookmark *> *)readiumBookmarksForIdentifier:(nonnull NSString *)identifier;
  
// Add readium bookmark for a book given its identifier
- (void)addReadiumBookmark:(nonnull NYPLReadiumBookmark *)bookmark
             forIdentifier:(nonnull NSString *)identifier;
  
/**
 Delete readium bookmark for a book given its identifer and saves updated registry
 to disk.
 */
- (void)deleteReadiumBookmark:(nonnull NYPLReadiumBookmark *)bookmark
                forIdentifier:(nonnull NSString *)identifier;

// Replace a readium bookmark with another, given its identifer
- (void)replaceBookmark:(nonnull NYPLReadiumBookmark *)oldBookmark
                   with:(nonnull NYPLReadiumBookmark *)newBookmark
          forIdentifier:(nonnull NSString *)identifier;

/// Returns the generic bookmarks for a any renderer's bookmarks given its identifier
/// @note Generic bookmarks are used for PDF documents.
- (nullable NSArray<NYPLBookLocation *> *)genericBookmarksForIdentifier:(nonnull NSString *)identifier;

// Add a generic bookmark (book location) for a book given its identifier
- (void)addGenericBookmark:(nonnull NYPLBookLocation *)bookmark
             forIdentifier:(nonnull NSString *)identifier;

// Delete a generic bookmark (book location) for a book given its identifier
- (void)deleteGenericBookmark:(nonnull NYPLBookLocation *)bookmark
                forIdentifier:(nonnull NSString *)identifier;

// Given an identifier, this method removes a book from the registry. Attempting to remove a book
// that is not present will result in an error being logged.
- (void)removeBookForIdentifier:(nonnull NSString *)book;

// Returns the thumbnail for a book via a handler called on the main thread. The book does not have
// to be registered in order to retrieve a cover.
- (void)thumbnailImageForBook:(nonnull NYPLBook *)book
                      handler:(void (^ _Nonnull)(UIImage * _Nonnull image))handler;

// Returns cover image if it exists, or falls back to thumbnail image load.
- (void)coverImageForBook:(nonnull NYPLBook *const)book
                  handler:(void (^ _Nonnull)(UIImage * _Nonnull image))handler;

// The set passed in should contain NYPLBook objects. If |books| is nil or does not strictly contain
// NYPLBook objects, the handler will be called with nil. Otherwise, the dictionary passed to the
// handler maps book identifiers to images. The handler is always called on the main thread. The
// books do not have to be registered in order to retrieve covers.
- (void)thumbnailImagesForBooks:(nonnull NSSet *)books
                        handler:(void (^ _Nonnull)(NSDictionary * _Nonnull bookIdentifiersToImages))handler;

// Immediately returns the cached thumbnail if available, else nil. Generated images are not
// returned. The book does not have to be registered in order to retrieve a cover.
- (nullable UIImage *)cachedThumbnailImageForBook:(nonnull NYPLBook *)book;

// Resets the registry to an empty state.
- (void)reset;

// Resets the registry for a specific account
- (void)reset:(nonnull NSString *)account;

/// Returns all book identifiers in the registry for a given account.
/// @note The identifiers returned should not be passed to @c -[NYPLBookRegistry @c bookForIdentifier:]
///       or similar methods unless the account provided to this method is also the currently active account.
/// @param account The id of the account to inspect.
/// @return A possibly empty array of book identifiers.
- (NSArray<NSString *> *_Nonnull)bookIdentifiersForAccount:(nonnull NSString *)account;

// Delay committing any changes from a sync indefinitely.
- (void)delaySyncCommit;

// Stop delaying committing synced data.
- (void)stopDelaySyncCommit;

/// Executes a function that does not modify the registry while the registry is set to a particular account, then
/// restores the registry to the original account afterwards. During the execution of @c block, the registry will
/// temporarily prevent access from other threads.
/// @warning It is an error to modify the registry during the execution of @c block. Doing so will result in undefined
///          behavior.
/// @param account The account to use while @c block is executing.
/// @param block   The function to execute while the registry is set to another account.
- (void)performUsingAccount:(nonnull NSString *)account
                      block:(void (^_Nonnull)(void))block;

@end

#if FEATURE_AUDIOBOOKS
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
@interface NYPLBookRegistry () <NYPLAudiobookRegistryProvider>

// Returns the audiobook bookmarks for an audiobook given its identifier
- (NSArray<NYPLAudiobookBookmark *> * _Nonnull)audiobookBookmarksForIdentifier:(NSString * _Nonnull)identifier;

// Add audiobook bookmark for a book given its identifier
- (void)addAudiobookBookmark:(NYPLAudiobookBookmark * _Nonnull)audiobookBookmark
               forIdentifier:(NSString * _Nonnull)identifier;

// Delete audiobook bookmark for a book given its identifer and saves updated registry to disk.
- (void)deleteAudiobookBookmark:(NYPLAudiobookBookmark * _Nonnull)audiobookBookmark
                  forIdentifier:(NSString * _Nonnull)identifier;

// Replace an audiobook bookmark with another, given its identifer
- (void)replaceAudiobookBookmark:(NYPLAudiobookBookmark * _Nonnull)oldAudiobookBookmark
        withNewAudiobookBookmark:(NYPLAudiobookBookmark * _Nonnull)newAudiobookBookmark
                   forIdentifier:(NSString * _Nonnull)identifier;

@end
#pragma clang diagnostic pop
#endif
