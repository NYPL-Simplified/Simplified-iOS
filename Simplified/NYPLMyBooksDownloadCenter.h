#import "NYPLBook.h"

static NSString *const NYPLMyBooksDownloadCenterDidChange =
  @"NYPLMyBooksDownloadCenterDidChange";

@interface NYPLMyBooksDownloadCenter : NSObject

+ (NYPLMyBooksDownloadCenter *)sharedDownloadCenter;

// This method will request credentials from the user if necessary.
- (void)startDownloadForBook:(NYPLBook *)book;

// This should only be called when a download is actually occurring. To simply reset the state of a
// book whose download has failed, one simply needs to change the state in the registry.
- (void)cancelDownloadForBookIdentifier:(NSString *)identifier;

// The value returned is in the range [0.0, 1.0].
- (double)downloadProgressForBookIdentifier:(NSString *)bookIdentifier;

@end
