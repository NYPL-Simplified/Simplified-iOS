#import "NYPLBook.h"

static NSString *const NYPLMyBooksDownloadCenterDidChange =
  @"NYPLMyBooksDownloadCenterDidChange";

@interface NYPLMyBooksDownloadCenter : NSObject

+ (NYPLMyBooksDownloadCenter *)sharedDownloadCenter;

- (void)startDownloadForBook:(NYPLBook *)book;

- (double)downloadProgressForBookIdentifier:(NSString *)bookIdentifier;

@end
