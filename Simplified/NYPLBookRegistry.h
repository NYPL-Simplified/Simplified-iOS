// All methods of this class declared below are thread-safe.

#import "NYPLBook.h"

@interface NYPLBookRegistry : NSObject

+ (NYPLBookRegistry *)sharedRegistry;

// Returns the URL of the directory used by the registry for storing content and metadata. The
// directory is not guaranteed to exist at the time this method is called.
- (NSURL *)registryDirectory;

// Adds a book to the book registry until it is manually removed. It allows the application to
// present information about obtained books when offline. Attempting to add a book already present
// will overwrite the existing book as if |updateBook:| were called.
- (void)addBook:(NYPLBook *)book;

// This method should be called whenever new book information is retreived from a server. Doing so
// ensures that once the user has seen the new information, they will continue to do so when
// accessing the application off-line or when viewing books outside of the catalog. Attempts to
// update a book not already stored in the registry will simply be ignored, so it's reasonable to
// call this method whenever new information is obtained regardless of a given book's state.
- (void)updateBook:(NYPLBook *)book;

// Returns the book for a given identifier if it is registered, else nil.
- (NYPLBook *)bookForIdentifier:(NSString *const)identifier;

// Given an identifier, this method removes a book from the registry. Attempting to remove a book
// that is not present will result in an error being logged.
- (void)removeBookForIdentifier:(NSString *const)book;

@end
