#import "NSString+NYPLStringAdditions.h"
#import "NYPLAccount.h"
#import "NYPLSettingsAccountViewController.h"
#import "NYPLBasicAuth.h"
#import "NYPLBook.h"
#import "NYPLBookAcquisition.h"
#import "NYPLBookCoverRegistry.h"
#import "NYPLBookRegistry.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLMyBooksDownloadInfo.h"
#import <ADEPT/ADEPT.h>

@interface NYPLMyBooksDownloadCenter ()
  <NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate, NYPLADEPTDelegate,
   UIAlertViewDelegate>

@property (nonatomic) NSString *bookIdentifierOfBookToRemove;
@property (nonatomic) NSMutableDictionary *bookIdentifierToDownloadInfo;
@property (nonatomic) BOOL broadcastScheduled;
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
  
  [NYPLADEPT sharedInstance].delegate = self;
  
  NSURLSessionConfiguration *const configuration =
    [NSURLSessionConfiguration ephemeralSessionConfiguration];
  
  self.bookIdentifierToDownloadInfo = [NSMutableDictionary dictionary];
  
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
      downloadTask:(NSURLSessionDownloadTask *const)downloadTask
      didWriteData:(int64_t const)bytesWritten
 totalBytesWritten:(int64_t const)totalBytesWritten
totalBytesExpectedToWrite:(int64_t const)totalBytesExpectedToWrite
{
  NSNumber *const key = @(downloadTask.taskIdentifier);
  NYPLBook *const book = self.taskIdentifierToBook[key];
  
  if(!book) {
    // A reset must have occurred.
    return;
  }
  
  // We update the rights management status based on the MIME type given to us by the server. We do
  // this only once at the point when we first start receiving data.
  if(bytesWritten == totalBytesWritten) {
    if([downloadTask.response.MIMEType isEqualToString:@"application/vnd.adobe.adept+xml"]) {
      self.bookIdentifierToDownloadInfo[book.identifier] =
      [[self downloadInfoForBookIdentifier:book.identifier]
       withRightsManagement:NYPLMyBooksDownloadRightsManagementAdobe];
    } else if([downloadTask.response.MIMEType isEqualToString:@"application/epub+zip"]) {
      self.bookIdentifierToDownloadInfo[book.identifier] =
      [[self downloadInfoForBookIdentifier:book.identifier]
       withRightsManagement:NYPLMyBooksDownloadRightsManagementNone];
    } else {
      NYPLLOG_F(@"Presuming no DRM for unrecognized MIME type \"%@\".",
                downloadTask.response.MIMEType);
      self.bookIdentifierToDownloadInfo[book.identifier] =
      [[self downloadInfoForBookIdentifier:book.identifier]
       withRightsManagement:NYPLMyBooksDownloadRightsManagementNone];
    }
  }
  
  // If the book is protected by Adobe DRM, the download will be very tiny and a later fulfillment
  // step will be required to get the actual content. As such, we only report progress for books not
  // protected by Adobe DRM at this stage.
  if([self downloadInfoForBookIdentifier:book.identifier].rightsManagement != NYPLMyBooksDownloadRightsManagementAdobe) {
    if(totalBytesExpectedToWrite > 0) {
      self.bookIdentifierToDownloadInfo[book.identifier] =
        [[self downloadInfoForBookIdentifier:book.identifier]
         withDownloadProgress:(totalBytesWritten / (double) totalBytesExpectedToWrite)];
      
      [self broadcastUpdate];
    }
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
  
  switch([self downloadInfoForBookIdentifier:book.identifier].rightsManagement) {
    case NYPLMyBooksDownloadRightsManagementUnknown:
      @throw NSInternalInconsistencyException;
    case NYPLMyBooksDownloadRightsManagementAdobe:
      // FIXME: Temporary test code!
      [[NYPLADEPT sharedInstance]
       fulfillWithACSMData:[NSData dataWithContentsOfURL:location]
       tag:book.identifier];
      break;
    case NYPLMyBooksDownloadRightsManagementNone: {
      [[NSFileManager defaultManager]
       removeItemAtURL:[self fileURLForBookIndentifier:book.identifier]
       error:NULL];
      NSError *error = nil;
      BOOL const success = [[NSFileManager defaultManager]
                            moveItemAtURL:location
                            toURL:[self fileURLForBookIndentifier:book.identifier]
                            error:&error];
      
      if(!success) {
        NYPLLOG(@"Failed to move temporary file after download completion.");
        [self failDownloadForBook:book];
        return;
      }
      [[NYPLBookRegistry sharedRegistry]
        setState:NYPLBookStateDownloadSuccessful forIdentifier:book.identifier];
      break;
    }
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

  // FIXME: This is commented out because we can't remove this stuff if a book will need to be
  // fulfilled. Perhaps this logic should just be put a different place.
  /*
  [self.bookIdentifierToDownloadInfo removeObjectForKey:book.identifier];
  
  // Even though |URLSession:downloadTask|didFinishDownloadingToURL:| needs this, it's safe to
  // remove it here because the aforementioned method will be called first.
  [self.taskIdentifierToBook removeObjectForKey:
      @(task.taskIdentifier)];
  */
  
  if(error && error.code != NSURLErrorCancelled) {
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

#pragma mark NYPLADEPTDelegate

- (void)adept:(__attribute__((unused)) NYPLADEPT *)adept didUpdateProgress:(double)progress tag:(NSString *)tag
{
  self.bookIdentifierToDownloadInfo[tag] =
    [[self downloadInfoForBookIdentifier:tag] withDownloadProgress:progress];
  
  [self broadcastUpdate];
}

- (void)adept:(__attribute__((unused)) NYPLADEPT *)adept didFinishDownloadingToURL:(NSURL *)URL fulfillmentID:(__attribute((unused)) NSString *)fulfillmentID isReturnable:(__attribute((unused)) BOOL)isReturnable rightsData:(NSData *)rightsData tag:(NSString *)tag
{
  // FIXME: CODE DUPLICATION!
  
  NYPLBook *const book = [[NYPLBookRegistry sharedRegistry] bookForIdentifier:tag];
  
  [[NSFileManager defaultManager]
   removeItemAtURL:[self fileURLForBookIndentifier:book.identifier]
   error:NULL];
  
  NSError *error = nil;
  
  // This needs to be a copy else the Adept connector will explode when it tries to delete the
  // temporary file.
  BOOL const success = [[NSFileManager defaultManager]
                        copyItemAtURL:URL
                        toURL:[self fileURLForBookIndentifier:book.identifier]
                        error:&error];
  
  if(!success) {
    NYPLLOG(@"Failed to move temporary file after download completion.");
    [self failDownloadForBook:book];
    return;
  }
  
  // FIXME: We only know to put it here beacuse of what part of the connector example code assumes.
  if(![rightsData writeToFile:[[[self fileURLForBookIndentifier:book.identifier] path]
                               stringByAppendingString:@"_rights.xml"]
                   atomically:YES]) {
    NYPLLOG(@"Failed to store rights data.");
  }
  
  [[NYPLBookRegistry sharedRegistry]
   setState:NYPLBookStateDownloadSuccessful forIdentifier:book.identifier];
  
  [self broadcastUpdate];
}

#pragma mark -

- (NYPLMyBooksDownloadInfo *)downloadInfoForBookIdentifier:(NSString *const)bookIdentifier
{
  return self.bookIdentifierToDownloadInfo[bookIdentifier];
}

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
  return [[[self contentDirectoryURL] URLByAppendingPathComponent:[identifier SHA256]]
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
    case NYPLBookStateDownloadSuccessful:
      // fallthrough
    case NYPLBookStateUsed:
      NYPLLOG(@"Ignoring nonsensical download request.");
      return;
  }
  
  if([NYPLAccount sharedAccount].hasBarcodeAndPIN) {
    NSURLRequest *const request = [NSURLRequest requestWithURL:[book.acquisition preferredURL]];
    
    if(!request.URL) {
      // Originally this code just let the request fail later on, but apparently resuming an
      // NSURLSessionDownloadTask created from a request with a nil URL pathetically results in a
      // segmentation fault.
      NYPLLOG(@"Aborting request with invalid URL.");
      [self failDownloadForBook:book];
      return;
    }
    
    NSURLSessionDownloadTask *const task = [self.session downloadTaskWithRequest:request];
    
    self.bookIdentifierToDownloadInfo[book.identifier] =
      [[NYPLMyBooksDownloadInfo alloc]
       initWithDownloadProgress:0.0
       downloadTask:task
       rightsManagement:NYPLMyBooksDownloadRightsManagementUnknown];
    
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
  } else {
    [NYPLSettingsAccountViewController
     requestCredentialsUsingExistingBarcode:NO
     completionHandler:^{
       [[NYPLMyBooksDownloadCenter sharedDownloadCenter] startDownloadForBook:book];
     }];
  }
}

- (void)cancelDownloadForBookIdentifier:(NSString *)identifier
{
  if(self.bookIdentifierToDownloadInfo[identifier]) {
    [[self downloadInfoForBookIdentifier:identifier].downloadTask
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
  for(NYPLMyBooksDownloadInfo *const info in [self.bookIdentifierToDownloadInfo allValues]) {
    [info.downloadTask cancelByProducingResumeData:nil];
  }
  
  [self.bookIdentifierToDownloadInfo removeAllObjects];
  [self.taskIdentifierToBook removeAllObjects];
  self.bookIdentifierOfBookToRemove = nil;
  
  [[NSFileManager defaultManager]
   removeItemAtURL:[self contentDirectoryURL]
   error:NULL];
  
  [self broadcastUpdate];
}

- (double)downloadProgressForBookIdentifier:(NSString *const)bookIdentifier
{
  return [self downloadInfoForBookIdentifier:bookIdentifier].downloadProgress;
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
