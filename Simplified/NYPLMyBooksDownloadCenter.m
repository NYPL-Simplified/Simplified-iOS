#import "NSMutableURLRequest+NYPLBasicAuthenticationAdditions.h"
#import "NYPLAccount.h"
#import "NYPLBook.h"
#import "NYPLMyBooksRegistry.h"
#import "NYPLMyBooksState.h"

#import "NYPLMyBooksDownloadCenter.h"

@interface NYPLMyBooksDownloadCenter () <NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate>

@property (nonatomic) BOOL broadcastScheduled;
@property (nonatomic) NSMutableDictionary *bookIdentifierToDownloadProgress;
@property (nonatomic) NSURLSession *session;
@property (nonatomic) NSMutableDictionary *taskIdentifierToBook;

@end

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
    [NSURLSessionConfiguration ephemeralSessionConfiguration];
  
  self.bookIdentifierToDownloadProgress = [NSMutableDictionary dictionary];
  
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
  NYPLMyBooksState const state = [[NYPLMyBooksRegistry sharedRegistry]
                                   stateForIdentifier:book.identifier];

  switch(state) {
    case NYPLMyBooksStateUnregistered:
      break;
    case NYPLMyBooksStateDownloading:
      // Ignore double button presses, et cetera.
      return;
    case NYPLMyBooksStateDownloadFailed:
      break;
    case NYPLMyBooksStateDownloadSuccessful:
      @throw NSInvalidArgumentException;
  }
  
  self.bookIdentifierToDownloadProgress[book.identifier] = [NSNumber numberWithDouble:0.0];
  
  NSMutableURLRequest *const request = [NSMutableURLRequest
                                        requestWithURL:book.acquisition.openAccess];
  
  [request setBasicAuthenticationUsername:[NYPLAccount sharedAccount].barcode
                                 password:[NYPLAccount sharedAccount].PIN];
  
  NSURLSessionDownloadTask *const task = [self.session downloadTaskWithRequest:request];
  
  self.taskIdentifierToBook[[NSNumber numberWithUnsignedLong:task.taskIdentifier]] = book;
  
  [task resume];
  
  [[NYPLMyBooksRegistry sharedRegistry] addBook:book state:NYPLMyBooksStateDownloading];
}

- (double)downloadProgressForBookIdentifier:(NSString *const)bookIdentifier
{
  return [self.bookIdentifierToDownloadProgress[bookIdentifier] doubleValue];
}

- (void)broadcastUpdate
{
  // We avoid issuing redundant notifications to prevent overwhelming UI updates.
  if(self.broadcastScheduled) return;
  
  self.broadcastScheduled = YES;
  
  [NSTimer scheduledTimerWithTimeInterval:0.2
                                   target:self
                                 selector:@selector(broadcastUpdateNow)
                                 userInfo:nil
                                  repeats:NO];
}

- (void)broadcastUpdateNow
{
  self.broadcastScheduled = NO;
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLMyBooksDownloadCenterDidChange
   object:self];
}

#pragma mark NSURLSessionDataDelegate

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
    self.bookIdentifierToDownloadProgress[book.identifier] =
      [NSNumber numberWithDouble:(totalBytesWritten / (double) totalBytesExpectedToWrite)];
    
    [self broadcastUpdate];
  }
}

- (void)URLSession:(__attribute__((unused)) NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(__attribute__((unused)) NSURL *)location
{
  NSNumber *const key = [NSNumber numberWithUnsignedLong:downloadTask.taskIdentifier];
  NYPLBook *const book = self.taskIdentifierToBook[key];
  
  // TODO: Copy file to permanent location here.
  
  self.bookIdentifierToDownloadProgress[book.identifier] = [NSNumber numberWithDouble:1.0];
  
  [[NYPLMyBooksRegistry sharedRegistry]
   setState:NYPLMyBooksStateDownloadSuccessful forIdentifier:book.identifier];
  
  [self broadcastUpdate];
}

#pragma mark NSURLSessionTaskDelegate

- (void)URLSession:(__attribute__((unused)) NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
  NSNumber *const key = [NSNumber numberWithUnsignedLong:task.taskIdentifier];
  NYPLBook *const book = self.taskIdentifierToBook[key];
  
  if(error) {
    self.bookIdentifierToDownloadProgress[book.identifier] = [NSNumber numberWithDouble:1.0];
    
    [[NYPLMyBooksRegistry sharedRegistry]
     setState:NYPLMyBooksStateDownloadFailed forIdentifier:book.identifier];
    
    [self broadcastUpdate];
  }
}

@end
