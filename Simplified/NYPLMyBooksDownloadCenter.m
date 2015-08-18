#import "NSString+NYPLStringAdditions.h"
#import "NYPLAccount.h"
#import "NYPLSettingsAccountViewController.h"
#import "NYPLBasicAuth.h"
#import "NYPLBook.h"
#import "NYPLBookAcquisition.h"
#import "NYPLBookCoverRegistry.h"
#import "NYPLBookRegistry.h"
#import "NYPLOPDSFeed.h"

#import "NYPLMyBooksDownloadCenter.h"

@interface NYPLMyBooksDownloadCenter ()
  <NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate, UIAlertViewDelegate>

@property (nonatomic) NSURLSession *session;
@property (nonatomic) BOOL broadcastScheduled;
@property (nonatomic) NSMutableDictionary *bookIdentifierToDownloadProgress;
@property (nonatomic) NSMutableDictionary *bookIdentifierToDownloadTask;
@property (nonatomic) NSMutableDictionary *taskIdentifierToBook;
@property (nonatomic) NSString *bookIdentifierOfBookToRemove;

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

#pragma mark NSURLSessionDownloadDelegate

// All of these delegate methods can be called (in very rare circumstances) after the shared
// download center has been reset. As such, they must be careful to bail out immediately if that is
// the case.

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
  NSNumber *const key = @(downloadTask.taskIdentifier);
  NYPLBook *const book = self.taskIdentifierToBook[key];
  
  if(!book) {
    // A reset must have occurred.
    return;
  }
  
  if(totalBytesExpectedToWrite > 0) {
    self.bookIdentifierToDownloadProgress[book.identifier] =
        @(totalBytesWritten / (double) totalBytesExpectedToWrite);
    
    [self broadcastUpdate];
  }
}

- (void)URLSession:(__attribute__((unused)) NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *const)downloadTask
didFinishDownloadingToURL:(NSURL *const)location
{
  NYPLBook *const book = self.taskIdentifierToBook[@(downloadTask.taskIdentifier)];
  
  if(!book) {
    // A reset must have occurred.
    return;
  }
  
  NSError *error = nil;
  
  [[NSFileManager defaultManager]
   removeItemAtURL:[self fileURLForBookIndentifier:book.identifier]
   error:NULL];
  
  BOOL const success = [[NSFileManager defaultManager]
                        moveItemAtURL:location
                        toURL:[self fileURLForBookIndentifier:book.identifier]
                        error:&error];
  
  if(success) {
    [[NYPLBookRegistry sharedRegistry]
     setState:NYPLBookStateDownloadSuccessful forIdentifier:book.identifier];
    [[NYPLBookRegistry sharedRegistry] save];
  } else {
    [[[UIAlertView alloc]
      initWithTitle:NSLocalizedString(@"DownloadFailed", nil)
      message:[NSString stringWithFormat:@"%@ (Error %ld)",
               [NSString
                stringWithFormat:NSLocalizedString(@"DownloadCouldNotBeCompletedFormat", nil),
                book.title],
               (long)error.code]
      delegate:nil
      cancelButtonTitle:nil
      otherButtonTitles:NSLocalizedString(@"OK", nil), nil]
     show];
    
    [[NYPLBookRegistry sharedRegistry]
     setState:NYPLBookStateDownloadFailed
     forIdentifier:book.identifier];
  }
  
  [self broadcastUpdate];
}

#pragma mark NSURLSessionTaskDelegate

// As with the NSURLSessionDownloadDelegate methods, we need to be mindful of resets for the task
// delegate methods too.

- (void)URLSession:(__attribute__((unused)) NSURLSession *)session
              task:(__attribute__((unused)) NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *const)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                             NSURLCredential *credential))completionHandler
{
  NYPLBasicAuthHandler(challenge, completionHandler);
}

- (void)URLSession:(__attribute__((unused)) NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
  NSNumber *const key = @(task.taskIdentifier);
  NYPLBook *const book = self.taskIdentifierToBook[key];
  
  if(!book) {
    // A reset must have occurred.
    return;
  }
  
  [self.bookIdentifierToDownloadProgress removeObjectForKey:book.identifier];
  
  // This is safe to remove because we only keep this around to be able to cancel downloads.
  [self.bookIdentifierToDownloadTask removeObjectForKey:book.identifier];
  
  // Even though |URLSession:downloadTask|didFinishDownloadingToURL:| needs this, it's safe to
  // remove it here because the aforementioned method will be called first.
  [self.taskIdentifierToBook removeObjectForKey:
      @(task.taskIdentifier)];
  
  if(error && error.code != NSURLErrorCancelled) {
    self.bookIdentifierToDownloadProgress[book.identifier] = @1.0;
    [self failDownloadForBook:book];
    return;
  }
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView
didDismissWithButtonIndex:(NSInteger const)buttonIndex
{
  if(buttonIndex == alertView.firstOtherButtonIndex) {
    if(![[NSFileManager defaultManager]
         removeItemAtURL:[self fileURLForBookIndentifier:self.bookIdentifierOfBookToRemove]
         error:NULL]){
      NYPLLOG(@"Failed to remove local content for download.");
    }
    
    [[NYPLBookRegistry sharedRegistry]
     removeBookForIdentifier:self.bookIdentifierOfBookToRemove];
  }
  
  self.bookIdentifierOfBookToRemove = nil;
}

#pragma mark -

- (NSURL *)contentDirectoryURL
{
  NSArray *const paths =
  NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
  
  assert([paths count] == 1);
  
  NSString *const path = paths[0];
  
  NSURL *const directoryURL =
    [[[NSURL fileURLWithPath:path]
      URLByAppendingPathComponent:[[NSBundle mainBundle]
                                   objectForInfoDictionaryKey:@"CFBundleIdentifier"]]
     URLByAppendingPathComponent:@"content"];

  if(![[NSFileManager defaultManager]
       createDirectoryAtURL:directoryURL
       withIntermediateDirectories:YES
       attributes:nil
       error:NULL]) {
    NYPLLOG(@"Failed to create directory.");
    return nil;
  }
  
  return directoryURL;
}

- (NSURL *)fileURLForBookIndentifier:(NSString *const)identifier
{
  NSString *const encodedIdentifier =
    [identifier fileSystemSafeBase64EncodedStringUsingEncoding:NSUTF8StringEncoding];
  
  return [[[self contentDirectoryURL] URLByAppendingPathComponent:encodedIdentifier]
          URLByAppendingPathExtension:@"epub"];
}

- (void)failDownloadForBook:(NYPLBook *const)book
{
  [[NYPLBookRegistry sharedRegistry]
   addBook:book
   location:nil
   state:NYPLBookStateDownloadFailed];
  
  [[[UIAlertView alloc]
    initWithTitle:NSLocalizedString(@"DownloadFailed", nil)
    message:[NSString stringWithFormat:NSLocalizedString(@"DownloadCouldNotBeCompletedFormat", nil),
             book.title]
    delegate:nil
    cancelButtonTitle:nil
    otherButtonTitles:NSLocalizedString(@"OK", nil), nil]
   show];
  
  [self broadcastUpdate];
}

- (void)startDownloadForBook:(NYPLBook *const)book
{
  NYPLBookState const state = [[NYPLBookRegistry sharedRegistry]
                               stateForIdentifier:book.identifier];
  
  switch(state) {
    case NYPLBookStateUnregistered:
      break;
    case NYPLBookStateDownloading:
      // Ignore double button presses, et cetera.
      return;
    case NYPLBookStateDownloadFailed:
      break;
    case NYPLBookStateDownloadNeeded:
      break;
    case NYPLBookStateHolding:
      break;
    case NYPLBookStateDownloadSuccessful:
      // fallthrough
    case NYPLBookStateUsed:
      NYPLLOG(@"Ignoring nonsensical download request.");
      return;
  }
  
  if([NYPLAccount sharedAccount].hasBarcodeAndPIN) {
    if(state == NYPLBookStateUnregistered || state == NYPLBookStateHolding) {
      // Check out the book
      [NYPLOPDSFeed withURL:book.acquisition.borrow completionHandler:^(NYPLOPDSFeed *feed) {
        if (!feed || feed.entries.count < 1) {
          NYPLLOG(@"Failed to check out book.");
          return;
        }
        
        NYPLBook *book = [NYPLBook bookWithEntry:feed.entries[0]];
        
        [[NYPLBookRegistry sharedRegistry]
         addBook:book
         location:nil
         state:NYPLBookStateDownloadNeeded];
        
        [[NYPLMyBooksDownloadCenter sharedDownloadCenter] startDownloadForBook:book];
      }];
    } else {
      // Actually download the book
      NSURLRequest *const request = [NSURLRequest requestWithURL:book.acquisition.generic];
      
      if(!request.URL) {
        // Originally this code just let the request fail later on, but apparently resuming an
        // NSURLSessionDownloadTask created from a request with a nil URL pathetically results in a
        // segmentation fault.
        NYPLLOG(@"Aborting request with invalid URL.");
        [self failDownloadForBook:book];
        return;
      }
      
      NSURLSessionDownloadTask *const task = [self.session downloadTaskWithRequest:request];
      
      self.bookIdentifierToDownloadProgress[book.identifier] = @0.0;
      self.bookIdentifierToDownloadTask[book.identifier] = task;
      self.taskIdentifierToBook[@(task.taskIdentifier)] = book;
      
      [task resume];
      
      [[NYPLBookRegistry sharedRegistry]
       addBook:book
       location:nil
       state:NYPLBookStateDownloading];
      
      // It is important to issue this immediately because a previous download may have left the
      // progress for the book at greater than 0.0 and we do not want that to be temporarily shown to
      // the user. As such, calling |broadcastUpdate| is not appropriate due to the delay.
      [[NSNotificationCenter defaultCenter]
       postNotificationName:NYPLMyBooksDownloadCenterDidChangeNotification
       object:self];
    }
  } else {
    [NYPLSettingsAccountViewController
     requestCredentialsUsingExistingBarcode:NO
     completionHandler:^{
       [[NYPLMyBooksDownloadCenter sharedDownloadCenter] startDownloadForBook:book];
     }];
  }
}

- (void)startDownloadForPreloadedBook:(NYPLBook *)book {
  NYPLBookState const state = [[NYPLBookRegistry sharedRegistry]
                               stateForIdentifier:book.identifier];
  
  switch(state) {
    case NYPLBookStateUnregistered:
      break;
    case NYPLBookStateDownloading:
      // Ignore double button presses, et cetera.
      return;
    case NYPLBookStateDownloadFailed:
      break;
    case NYPLBookStateDownloadNeeded:
      break;
    case NYPLBookStateDownloadSuccessful:
      // fallthrough
    case NYPLBookStateUsed:
      NYPLLOG(@"Ignoring nonsensical download request.");
      return;
  }
  
  // Actually download the book
  NSURLRequest *const request = [NSURLRequest requestWithURL:book.acquisition.generic];
  
  if(!request.URL) {
    // Originally this code just let the request fail later on, but apparently resuming an
    // NSURLSessionDownloadTask created from a request with a nil URL pathetically results in a
    // segmentation fault.
    NYPLLOG(@"Aborting request with invalid URL.");
    return;
  }
  
  NSURLSessionDownloadTask *const task = [self.session downloadTaskWithRequest:request];
  
  self.bookIdentifierToDownloadProgress[book.identifier] = @0.0;
  self.bookIdentifierToDownloadTask[book.identifier] = task;
  self.taskIdentifierToBook[@(task.taskIdentifier)] = book;
  
  [task resume];
  
  [[NYPLBookRegistry sharedRegistry]
   addBook:book
   location:nil
   state:NYPLBookStateDownloading];
  
  // It is important to issue this immediately because a previous download may have left the
  // progress for the book at greater than 0.0 and we do not want that to be temporarily shown to
  // the user. As such, calling |broadcastUpdate| is not appropriate due to the delay.
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLMyBooksDownloadCenterDidChangeNotification
   object:self];
}

- (void)cancelDownloadForBookIdentifier:(NSString *)identifier
{
  if(self.bookIdentifierToDownloadTask[identifier]) {
    [(NSURLSessionDownloadTask *)self.bookIdentifierToDownloadTask[identifier]
     cancelByProducingResumeData:^(__attribute__((unused)) NSData *resumeData) {
       [[NYPLBookRegistry sharedRegistry]
        setState:NYPLBookStateDownloadNeeded forIdentifier:identifier];
       
       [self broadcastUpdate];
     }];
  } else {
    // The download was not actually going, so we just need to convert a failed download state.
    NYPLBookState const state = [[NYPLBookRegistry sharedRegistry]
                                 stateForIdentifier:identifier];
    
    if(state != NYPLBookStateDownloadFailed) {
      NYPLLOG(@"Ignoring nonsensical cancellation request.");
      return;
    }
    
    [[NYPLBookRegistry sharedRegistry]
     setState:NYPLBookStateDownloadNeeded forIdentifier:identifier];
  }
}

- (void)removeCompletedDownloadForBookIdentifier:(NSString *const)identifier
{
  if(self.bookIdentifierOfBookToRemove) {
    NYPLLOG(@"Ignoring delete while still handling previous delete.");
    return;
  }
  
  self.bookIdentifierOfBookToRemove = identifier;
  
  [[[UIAlertView alloc]
    initWithTitle:NSLocalizedString(@"MyBooksDownloadCenterConfirmDeleteTitle", nil)
    message:[NSString stringWithFormat:
             NSLocalizedString(@"MyBooksDownloadCenterConfirmDeleteTitleMessageFormat", nil),
             [[NYPLBookRegistry sharedRegistry] bookForIdentifier:identifier].title]
    delegate:self
    cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
    otherButtonTitles:@"Delete", nil]
   show];
}

- (void)reset
{
  for(NSURLSessionDownloadTask *const task in [self.bookIdentifierToDownloadTask allValues]) {
    [task cancelByProducingResumeData:nil];
  }
  
  [self.bookIdentifierToDownloadProgress removeAllObjects];
  [self.bookIdentifierToDownloadTask removeAllObjects];
  [self.taskIdentifierToBook removeAllObjects];
  self.bookIdentifierOfBookToRemove = nil;
  
  [[NSFileManager defaultManager]
   removeItemAtURL:[self contentDirectoryURL]
   error:NULL];
  
  [self broadcastUpdate];
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
  
  // This needs to be queued on the main run loop. If we queue it elsewhere, it may end up never
  // firing due to a run loop becoming inactive.
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [self performSelector:@selector(broadcastUpdateNow)
               withObject:nil
               afterDelay:0.2];
  }];
}

- (void)broadcastUpdateNow
{
  self.broadcastScheduled = NO;
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLMyBooksDownloadCenterDidChangeNotification
   object:self];
}

@end
