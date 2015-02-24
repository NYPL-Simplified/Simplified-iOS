// All methods of this class declared below are thread-safe.

#import "NYPLMyBooksState.h"

@class NYPLBook;
@class NYPLBookLocation;

// This is broadcast whenever the book registry is modified.
static NSString *const NYPLBookRegistryDidChangeNotification
  = @"NYPLBookRegistryDidChangeNotification";

@interface NYPLMyBooksRegistry : NSObject

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (NYPLMyBooksRegistry *)sharedRegistry;

// Returns the URL of the directory used by the registry for storing content and metadata. The
// directory is not guaranteed to exist at the time this method is called.
- (NSURL *)registryDirectory;

// Saves the registry. This should be called before the application is terminated.
- (void)save;

// Syncs the latest content from the server.
- (void)syncWithCompletionHandler:(void (^)(BOOL success))handler;

// Adds a book to the book registry until it is manually removed. It allows the application to
// present information about obtained books when offline. Attempting to add a book already present
// will overwrite the existing book as if |updateBook:| were called. The location may be nil. The
// state provided must not be |NYPLMyBooksStateUnregistered|.
- (void)addBook:(NYPLBook *)book
       location:(NYPLBookLocation *)location
          state:(NYPLMyBooksState)state;

// This method should be called whenever new book information is retrieved from a server. Doing so
// ensures that once the user has seen the new information, they will continue to do so when
// accessing the application off-line or when viewing books outside of the catalog. Attempts to
// update a book not already stored in the registry will simply be ignored, so it's reasonable to
// call this method whenever new information is obtained regardless of a given book's state.
- (void)updateBook:(NYPLBook *)book;

// Returns the book for a given identifier if it is registered, else nil.
- (NYPLBook *)bookForIdentifier:(NSString *)identifier;

// Sets the state for a book previously registered given its identifier.
- (void)setState:(NYPLMyBooksState)state forIdentifier:(NSString *)identifier;

// Returns the state of a book given its identifier.
- (NYPLMyBooksState)stateForIdentifier:(NSString *)identifier;

// Sets the location for a book previously registered given its identifier.
- (void)setLocation:(NYPLBookLocation *)location forIdentifier:(NSString *)identifier;

// Returns the location of a book given its identifier.
- (NYPLBookLocation *)locationForIdentifier:(NSString *)identifier;

// Given an identifier, this method removes a book from the registry. Attempting to remove a book
// that is not present will result in an error being logged.
- (void)removeBookForIdentifier:(NSString *)book;

// Resets the registry to an empty state.
- (void)reset;

// Returns the number of books currently registered.
- (NSUInteger)count;

// Returns all registered books.
- (NSArray *)allBooks;

@end
