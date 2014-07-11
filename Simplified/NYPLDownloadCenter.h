#import "NYPLBook.h"

@interface NYPLDownloadCenter : NSObject

+ (NYPLDownloadCenter *)sharedDownloadCenter;

- (void)startDownloadForBook:(NYPLBook *)book;

@end
