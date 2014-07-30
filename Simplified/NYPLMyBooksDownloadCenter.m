#import "NYPLAccount.h"
#import "NYPLBook.h"
#import "NYPLMyBooksRegistry.h"
#import "NYPLMyBooksState.h"
#import "NYPLSettingsCredentialViewController.h"
#import "NYPLRootTabBarController.h"

#import "NYPLMyBooksDownloadCenter.h"

@interface NYPLMyBooksDownloadCenter () <NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate>

@property (nonatomic) NSURLSession *session;
@property (nonatomic) BOOL broadcastScheduled;

@property (nonatomic) NSMutableDictionary *bookIdentifierToDownloadProgress;
@property (nonatomic) NSMutableDictionary *bookIdentifierToDownloadTask;
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
  self.bookIdentifierToDownloadTask = [NSMutableDictionary dictionary];
  
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
    case NYPLMyBooksStateDownloadNeeded:
      break;
    case NYPLMyBooksStateDownloadSuccessful:
      @throw NSInvalidArgumentException;
  }
  
  if([NYPLAccount sharedAccount].hasBarcodeAndPIN) {
    NSURLRequest *const request = [NSURLRequest requestWithURL:book.acquisition.openAccess];
    
    if(!request.URL) {
      // Originally this code just let the request fail later on, but apparently resuming an
      // NSURLSessionDownloadTask created from a request with a nil URL pathetically results in a
      // segmentation fault.
      NYPLLOG(@"Aborting request with invalid URL.");
      [[NYPLMyBooksRegistry sharedRegistry] addBook:book state:NYPLMyBooksStateDownloadFailed];
      [self broadcastUpdate];
      return;
    }
    
    NSURLSessionDownloadTask *const task = [self.session downloadTaskWithRequest:request];
    
    self.bookIdentifierToDownloadProgress[book.identifier] = [NSNumber numberWithDouble:0.0];
    self.bookIdentifierToDownloadTask[book.identifier] = task;
    self.taskIdentifierToBook[[NSNumber numberWithUnsignedLong:task.taskIdentifier]] = book;
    
    [task resume];
    
    [[NYPLMyBooksRegistry sharedRegistry] addBook:book state:NYPLMyBooksStateDownloading];
  } else {
    [[NYPLSettingsCredentialViewController sharedController]
     requestCredentialsFromViewController:[NYPLRootTabBarController sharedController]
     useExistingBarcode:NO
     message:NYPLSettingsCredentialViewControllerMessageLogInToDownloadBook
     completionHandler:^{
       [[NYPLMyBooksDownloadCenter sharedDownloadCenter] startDownloadForBook:book];
     }];
  }
}

- (void)cancelDownloadForBookIdentifier:(NSString *)identifier
{
  if(self.bookIdentifierToDownloadTask[identifier]) {
    [(NSURLSessionDownloadTask *)self.bookIdentifierToDownloadTask[identifier]
     cancelByProducingResumeData:^(__attribute__((unused)) NSData *resumeData) {
       [[NYPLMyBooksRegistry sharedRegistry]
        setState:NYPLMyBooksStateDownloadNeeded forIdentifier:identifier];
       
       [self broadcastUpdate];
     }];
  } else {
    // The download was not actually going, so we just need to convert a failed download state.
    NYPLMyBooksState const state = [[NYPLMyBooksRegistry sharedRegistry]
                                    stateForIdentifier:identifier];
    
    if(state != NYPLMyBooksStateDownloadFailed) {
      NYPLLOG(@"Ignoring nonsensical cancellation request.");
      return;
    }
    
    [[NYPLMyBooksRegistry sharedRegistry]
     setState:NYPLMyBooksStateDownloadNeeded forIdentifier:identifier];
  }
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
      downloadTask:(__attribute__((unused)) NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(__attribute__((unused)) NSURL *)location
{
  // TODO: Copy file to permanent location here.
}

#pragma mark NSURLSessionTaskDelegate

- (void)URLSession:(__attribute__((unused)) NSURLSession *)session
              task:(__attribute__((unused)) NSURLSessionTask *)task
didReceiveChallenge:(__attribute__((unused)) NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                             NSURLCredential *credential))completionHandler
{
  completionHandler(NSURLSessionAuthChallengeUseCredential,
                    [NSURLCredential
                     credentialWithUser:[NYPLAccount sharedAccount].barcode
                     password:[NYPLAccount sharedAccount].PIN
                     persistence:NSURLCredentialPersistenceNone]);
}

- (void)URLSession:(__attribute__((unused)) NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
  NSNumber *const key = [NSNumber numberWithUnsignedLong:task.taskIdentifier];
  NYPLBook *const book = self.taskIdentifierToBook[key];
  
  [self.bookIdentifierToDownloadProgress removeObjectForKey:book.identifier];
  
  // This is safe to remove because we only keep this around to be able to cancel downloads.
  [self.bookIdentifierToDownloadTask removeObjectForKey:book.identifier];
  
  // Even though |URLSession:downloadTask|didFinishDownloadingToURL:| needs this, it's safe to
  // remove it here because the aforementioned method will be called first.
  [self.taskIdentifierToBook removeObjectForKey:
   [NSNumber numberWithUnsignedLong:task.taskIdentifier]];
  
  if(error && error.code != NSURLErrorCancelled) {
    self.bookIdentifierToDownloadProgress[book.identifier] = [NSNumber numberWithDouble:1.0];
    
    [[NYPLMyBooksRegistry sharedRegistry]
     setState:NYPLMyBooksStateDownloadFailed forIdentifier:book.identifier];
    
    [self broadcastUpdate];
  }
  
  if(!error) {
    [[NYPLMyBooksRegistry sharedRegistry]
     setState:NYPLMyBooksStateDownloadSuccessful forIdentifier:book.identifier];
    
    [self broadcastUpdate];
  }
}

@end
