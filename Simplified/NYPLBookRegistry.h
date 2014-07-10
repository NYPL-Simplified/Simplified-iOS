// All methods of this class declared below are thread-safe.

#import "NYPLBook.h"

// This is broadcast whenever the book registry is modified.
static NSString *const NYPLBookRegistryDidChange = @"NYPLBookRegistryDidChange";

@interface NYPLBookRegistry : NSObject

+ (NYPLBookRegistry *)sharedRegistry;

// Returns the URL of the directory used by the registry for storing content and metadata. The
// directory is not guaranteed to exist at the time this method is called.
- (NSURL *)registryDirectory;

// Saves the registry. This should be called before the application is terminated.
- (void)save;

// Returns a book object given an OPDS entry. The advantage of creating a book via this method is
// that the state of the book will be set approprtiately given the current state of the registry. It
// will also update the metadata in the registry if the entry differs from what's currently stored.
- (NYPLBook *)bookWithEntry:(NYPLOPDSEntry *)entry;

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

// Returns the number of books currently registered.
- (NSUInteger)count;

// Returns all registered books sorted via the block provided.
- (NSArray *)allBooksSortedByBlock:(NSComparisonResult (^)(NYPLBook *a, NYPLBook *b))block;

@end
