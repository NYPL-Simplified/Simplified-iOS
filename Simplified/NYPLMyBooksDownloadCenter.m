#import "NYPLBook.h"
#import "NYPLMyBooksRegistry.h"
#import "NYPLMyBooksState.h"

#import "NYPLMyBooksDownloadCenter.h"

@interface NYPLMyBooksDownloadCenter () <NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate>

@property (nonatomic) NSURLSession *session;
@property (nonatomic) NSMutableDictionary *taskIdentifierToBook;

@end

static NSString *const sessionIdentifier = @"NYPLMyBooksDownloadCenterSession";

@implementation NYPLMyBooksDownloadCenter

+ (NYPLMyBooksDownloadCenter *)sharedDownloadCenter
{
  static dispatch_once_t predicate;
  static NYPLMyBooksDownloadCenter *sharedDownloadCenter = nil;
  
  dispatch_once(&predicate, ^{
    sharedDownloadCenter = [[self alloc] init];
    if(!sharedDownloadCenter) {
      NYPLLOG(@"Failed to create shared download center.");
    }
  });
  
  return sharedDownloadCenter;
}

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  NSURLSessionConfiguration *const configuration =
    [NSURLSessionConfiguration backgroundSessionConfiguration:sessionIdentifier];
  
  self.session = [NSURLSession
                  sessionWithConfiguration:configuration
                  delegate:self
                  delegateQueue:[NSOperationQueue mainQueue]];
  
  self.taskIdentifierToBook = [NSMutableDictionary dictionary];
  
  return self;
}

#pragma mark -

- (void)startDownloadForBook:(NYPLBook *const)book
{
  [[NYPLMyBooksRegistry sharedRegistry] addBook:book state:NYPLMyBooksStateDownloading];
  
  NSURL *const testURL = [NSURL URLWithString:@"http://i.imgur.com/pLhJIXXXcm.gif"];
  
  NSURLSessionDownloadTask *const task =
    [self.session downloadTaskWithURL:testURL];
  
  self.taskIdentifierToBook[[NSNumber numberWithUnsignedLong:task.taskIdentifier]] = book;
  
  [task resume];
}

- (void)broadcastUpdateForBook:(NYPLBook *const)book
                        status:(NYPLMyBooksDownloadCenterStatus)status
                      progress:(double const)progress

{
  NSNumber *const progressNumber = [NSNumber numberWithDouble:progress];
  NSNumber *const statusNumber = [NSNumber numberWithInteger:status];
  
  NSDictionary *const userInfo = @{NYPLMyBooksDownloadCenterNotificationBookKey: book,
                                   NYPLMyBooksDownloadCenterNotificationProgressKey: progressNumber,
                                   NYPLMyBooksDownloadCenterNotificationStatusKey: statusNumber};
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLMyBooksDownloadCenterNotification
   object:self
   userInfo:userInfo];
}

#pragma mark NSURLSessionDownloadDelegate

- (void)URLSession:(__attribute__((unused)) NSURLSession *)session
      downloadTask:(__attribute__((unused)) NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(__attribute__((unused)) int64_t)fileOffset
expectedTotalBytes:(__attribute__((unused)) int64_t)expectedTotalBytes
{
  NYPLLOG(@"Ignoring unexpected resumption.");
}

- (void)URLSession:(__attribute__((unused)) NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(__attribute__((unused)) int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
  NSNumber *const key = [NSNumber numberWithUnsignedLong:downloadTask.taskIdentifier];
  NYPLBook *const book = self.taskIdentifierToBook[key];
  
  if(totalBytesExpectedToWrite > 0) {
    [self broadcastUpdateForBook:book
                          status:NYPLMyBooksDownloadCenterStatusDownloading
                        progress:(totalBytesWritten / (double) totalBytesExpectedToWrite)];
  }
}

- (void)URLSession:(__attribute__((unused)) NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(__attribute__((unused)) NSURL *)location
{
  NSNumber *const key = [NSNumber numberWithUnsignedLong:downloadTask.taskIdentifier];
  NYPLBook *const book = self.taskIdentifierToBook[key];
  
  // TODO: Copy file to permanent loction here.
  
  [self broadcastUpdateForBook:book
                        status:NYPLMyBooksDownloadCenterStatusSucceeded
                      progress:1.0];
}

#pragma mark NSURLSessionTaskDelegate

- (void)URLSession:(__attribute__((unused)) NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
  NSNumber *const key = [NSNumber numberWithUnsignedLong:task.taskIdentifier];
  NYPLBook *const book = self.taskIdentifierToBook[key];
  
  if(error) {
    [self broadcastUpdateForBook:book
                          status:NYPLMyBooksDownloadCenterStatusFailed
                        progress:1.0];
  }
}

@end
