#import "NYPLBook.h"

@interface NYPLMyBooksDownloadCenter : NSObject

+ (NYPLMyBooksDownloadCenter *)sharedDownloadCenter;

- (void)startDownloadForBook:(NYPLBook *)book;

@end
