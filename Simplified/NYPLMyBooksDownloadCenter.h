#import "NYPLBook.h"

typedef NS_ENUM(NSInteger, NYPLMyBooksDownloadCenterStatus) {
  NYPLMyBooksDownloadCenterStatusDownloading,
  NYPLMyBooksDownloadCenterStatusFailed,
  NYPLMyBooksDownloadCenterStatusSucceeded
};

// book     : NYPLBook
// progress : double                          (range 0..1, boxed as NSNumber)
// status   : NYPLMyBooksDownloadCenterStatus (boxed as NSNumber)
static NSString *const NYPLMyBooksDownloadCenterNotification =
  @"NYPLMyBooksDownloadCenterNotification";

static NSString *const NYPLMyBooksDownloadCenterNotificationBookKey = @"book";
static NSString *const NYPLMyBooksDownloadCenterNotificationProgressKey = @"progress";
static NSString *const NYPLMyBooksDownloadCenterNotificationStatusKey = @"status";

@interface NYPLMyBooksDownloadCenter : NSObject

+ (NYPLMyBooksDownloadCenter *)sharedDownloadCenter;

- (void)startDownloadForBook:(NYPLBook *)book;

@end
