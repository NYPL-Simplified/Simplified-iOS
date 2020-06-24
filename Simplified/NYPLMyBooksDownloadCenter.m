@import NYPLAudiobookToolkit;
@import OverdriveProcessor;

#import "NSString+NYPLStringAdditions.h"
#import "NYPLAccountSignInViewController.h"
#import "NYPLBasicAuth.h"
#import "NYPLBook.h"
#import "NYPLBookCoverRegistry.h"
#import "NYPLBookRegistry.h"
#import "NYPLOPDS.h"
#import "NYPLJSON.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLMyBooksDownloadInfo.h"

#import "NYPLMyBooksSimplifiedBearerToken.h"
#import "SimplyE-Swift.h"

#if defined(FEATURE_DRM_CONNECTOR)
#import <ADEPT/ADEPT.h>
@interface NYPLMyBooksDownloadCenter () <NYPLADEPTDelegate>
@end
#endif

@interface NYPLMyBooksDownloadCenter ()
  <NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate>

@property (nonatomic) NSString *bookIdentifierOfBookToRemove;
@property (nonatomic) NSMutableDictionary *bookIdentifierToDownloadInfo;
@property (nonatomic) NSMutableDictionary *bookIdentifierToDownloadProgress;
@property (nonatomic) NSMutableDictionary *bookIdentifierToDownloadTask;
@property (nonatomic) BOOL broadcastScheduled;
@property (nonatomic) NSURLSession *session;
@property (nonatomic) NSMutableDictionary *taskIdentifierToBook;

/// Maps a task identifier to a non-negative redirect attempt count. This
/// tracks the number of redirect attempts for a particular download task.
/// If a task identifier is not present in the dictionary, the redirect
/// attempt count for the associated task should be considered 0.
///
/// Tracking this explicitly is required because we override
/// @c URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler
/// in order to handle redirects when performing bearer token authentication.
@property (nonatomic) NSMutableDictionary<NSNumber *, NSNumber *> *taskIdentifierToRedirectAttempts;

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
  
#if defined(FEATURE_DRM_CONNECTOR)
  [NYPLADEPT sharedInstance].delegate = self;
#endif
  
  NSURLSessionConfiguration *const configuration =
    [NSURLSessionConfiguration ephemeralSessionConfiguration];
  
  self.bookIdentifierToDownloadInfo = [NSMutableDictionary dictionary];
  self.bookIdentifierToDownloadProgress = [NSMutableDictionary dictionary];
  self.bookIdentifierToDownloadTask = [NSMutableDictionary dictionary];
  
  self.session = [NSURLSession
                  sessionWithConfiguration:configuration
                  delegate:self
                  delegateQueue:[NSOperationQueue mainQueue]];
  
  self.taskIdentifierToBook = [NSMutableDictionary dictionary];
  self.taskIdentifierToRedirectAttempts = [NSMutableDictionary dictionary];
  
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
    } else if ([downloadTask.response.MIMEType
                isEqualToString:@"application/vnd.librarysimplified.bearer-token+json"]) {
      self.bookIdentifierToDownloadInfo[book.identifier] =
        [[self downloadInfoForBookIdentifier:book.identifier]
         withRightsManagement:NYPLMyBooksDownloadRightsManagementSimplifiedBearerTokenJSON];
    } else if ([downloadTask.response.MIMEType
                   isEqualToString:@"application/json"]) {
         self.bookIdentifierToDownloadInfo[book.identifier] =
           [[self downloadInfoForBookIdentifier:book.identifier]
            withRightsManagement:NYPLMyBooksDownloadRightsManagementOverdriveManifestJSON];
    } else {
      NYPLLOG_F(@"Presuming no DRM for unrecognized MIME type \"%@\".", downloadTask.response.MIMEType);
      NYPLMyBooksDownloadInfo *info =
      [[self downloadInfoForBookIdentifier:book.identifier]
       withRightsManagement:NYPLMyBooksDownloadRightsManagementNone];
      if (info) {
        self.bookIdentifierToDownloadInfo[book.identifier] = info;
      }
    }
  }
  
  // If the book is protected by Adobe DRM or a Simplified bearer token flow/Overdrive manifest JSON, the download will be very tiny and a later
  // fulfillment step will be required to get the actual content. As such, we do not report progress.
  NYPLMyBooksDownloadRightsManagement rightManagement = [self downloadInfoForBookIdentifier:book.identifier].rightsManagement;
  if((rightManagement != NYPLMyBooksDownloadRightsManagementAdobe)
     && (rightManagement != NYPLMyBooksDownloadRightsManagementSimplifiedBearerTokenJSON)
     && (rightManagement != NYPLMyBooksDownloadRightsManagementOverdriveManifestJSON))
  {
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

  [self.taskIdentifierToRedirectAttempts removeObjectForKey:@(downloadTask.taskIdentifier)];
  
  BOOL success = YES; 
  NYPLProblemDocument *problemDocument = nil;
  if ([downloadTask.response.MIMEType isEqualToString:@"application/problem+json"]
       || [downloadTask.response.MIMEType isEqualToString:@"application/api-problem+json"]) {
    NSError *problemDocumentParseError = nil;
    problemDocument = [NYPLProblemDocument fromData:[NSData dataWithContentsOfURL:location] error:&problemDocumentParseError];
    if (problemDocumentParseError) {
      [NYPLErrorLogger logProblemDocumentParseError:problemDocumentParseError
                                                url:location
                                            context:@"myBooks-download-finish"];
    }
    [[NSFileManager defaultManager] removeItemAtURL:location error:NULL];
    success = NO;
  }
  
  if (success) {
    switch([self downloadInfoForBookIdentifier:book.identifier].rightsManagement) {
      case NYPLMyBooksDownloadRightsManagementUnknown:
        @throw NSInternalInconsistencyException;
            
      case NYPLMyBooksDownloadRightsManagementAdobe:
      {
        
#if defined(FEATURE_DRM_CONNECTOR)
        
        NSData *ACSMData = [NSData dataWithContentsOfURL:location];
        NSString *PDFString = @">application/pdf</dc:format>";
        if([[[NSString alloc] initWithData:ACSMData encoding:NSUTF8StringEncoding] containsString:PDFString]) {
          dispatch_async(dispatch_get_main_queue(), ^{
            NSString *formattedMessage = [NSString stringWithFormat:NSLocalizedString(@"PDFNotSupportedDescriptionFormat", nil), book.title];
            UIAlertController *alert = [NYPLAlertUtils alertWithTitle:@"PDFNotSupported" message:formattedMessage];
            [NYPLAlertUtils presentFromViewControllerOrNilWithAlertController:alert viewController:nil animated:YES completion:nil];
          });
          
          [[NYPLBookRegistry sharedRegistry]
           setState:NYPLBookStateDownloadFailed
           forIdentifier:book.identifier];
          
        } else {
          
          NYPLLOG_F(@"Download finished. Fulfilling with userID: %@",[[NYPLUserAccount sharedAccount] userID]);
          [[NYPLADEPT sharedInstance]
           fulfillWithACSMData:ACSMData
           tag:book.identifier
           userID:[[NYPLUserAccount sharedAccount] userID]
           deviceID:[[NYPLUserAccount sharedAccount] deviceID]];
        }
        
#endif        
        break;
      }
      case NYPLMyBooksDownloadRightsManagementSimplifiedBearerTokenJSON: {
        NSData *const data = [NSData dataWithContentsOfURL:location];
        if (!data) {
          [self failDownloadForBook:book];
          break;
        }

        NSDictionary *const dictionary = NYPLJSONObjectFromData(data);
        if (![dictionary isKindOfClass:[NSDictionary class]]) {
          [self failDownloadForBook:book];
          break;
        }

        NYPLMyBooksSimplifiedBearerToken *const simplifiedBearerToken =
          [NYPLMyBooksSimplifiedBearerToken simplifiedBearerTokenWithDictionary:dictionary];

        if (!simplifiedBearerToken) {
          [self failDownloadForBook:book];
          break;
        }

        NSMutableURLRequest *const mutableRequest = [NSMutableURLRequest requestWithURL:simplifiedBearerToken.location];
        [mutableRequest setValue:[NSString stringWithFormat:@"Bearer %@", simplifiedBearerToken.accessToken]
              forHTTPHeaderField:@"Authorization"];

        NSURLSessionDownloadTask *const task = [self.session downloadTaskWithRequest:mutableRequest];

        self.bookIdentifierToDownloadInfo[book.identifier] =
          [[NYPLMyBooksDownloadInfo alloc]
           initWithDownloadProgress:0.0
           downloadTask:task
           rightsManagement:NYPLMyBooksDownloadRightsManagementNone];

        self.taskIdentifierToBook[@(task.taskIdentifier)] = book;

        [task resume];

        break;
      }
      case NYPLMyBooksDownloadRightsManagementOverdriveManifestJSON: {
          success = [self moveDownloadedFileAtURL:location book:book];
          break;
      }
      case NYPLMyBooksDownloadRightsManagementNone: {
        NSError *error = nil;
        
        [[NSFileManager defaultManager]
         removeItemAtURL:[self fileURLForBookIndentifier:book.identifier]
         error:NULL];
        
        success = [[NSFileManager defaultManager]
                   moveItemAtURL:location
                   toURL:[self fileURLForBookIndentifier:book.identifier]
                   error:&error];
        
        if(success) {
          [[NYPLBookRegistry sharedRegistry]
           setState:NYPLBookStateDownloadSuccessful forIdentifier:book.identifier];
          [[NYPLBookRegistry sharedRegistry] save];
        }
        
        break;
      }
    }
  }
  
  if (!success) {
    dispatch_async(dispatch_get_main_queue(), ^{
      NSString *formattedMessage = [NSString stringWithFormat:NSLocalizedString(@"DownloadCouldNotBeCompletedFormat", nil), book.title];
      UIAlertController *alert = [NYPLAlertUtils
                                  alertWithTitle:@"DownloadFailed"
                                  message:formattedMessage];
      if (problemDocument) {
        [[NYPLProblemDocumentCacheManager sharedInstance] cacheProblemDocument:problemDocument key:book.identifier];
        [NYPLAlertUtils setProblemDocumentWithController:alert document:problemDocument append:YES];
        
        if ([problemDocument.type isEqualToString:NYPLProblemDocument.TypeNoActiveLoan]) {
          [[NYPLBookRegistry sharedRegistry] removeBookForIdentifier:book.identifier];
        }
      }
      [NYPLAlertUtils presentFromViewControllerOrNilWithAlertController:alert viewController:nil animated:YES completion:nil];
    });
    
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

// This is implemented in order to be able to handle redirects when using
// bearer token authentication.
- (void)URLSession:(__unused NSURLSession *)session
              task:(NSURLSessionTask *const)task
willPerformHTTPRedirection:(__unused NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *const)request
 completionHandler:(void (^ const)(NSURLRequest *_Nullable))completionHandler
{
  NSUInteger const maxRedirectAttempts = 10;

  NSNumber *const redirectAttemptsNumber = self.taskIdentifierToRedirectAttempts[@(task.taskIdentifier)];
  NSUInteger const redirectAttempts = redirectAttemptsNumber ? redirectAttemptsNumber.unsignedIntegerValue : 0;

  if (redirectAttempts >= maxRedirectAttempts) {
    completionHandler(nil);
    return;
  }

  self.taskIdentifierToRedirectAttempts[@(task.taskIdentifier)] = @(redirectAttempts + 1);

  NSString *const authorizationKey = @"Authorization";

  // Since any "Authorization" header will be dropped on redirection for security
  // reasons, we need to again manually set the header for the redirected request
  // if we originally manually set the header to a bearer token. There's no way
  // to use NSURLSession's standard challenge handling approach for bearer tokens,
  // sadly.
  if ([task.originalRequest.allHTTPHeaderFields[authorizationKey] hasPrefix:@"Bearer"]) {
    // Do not pass on the bearer token to other domains.
    if (![task.originalRequest.URL.host isEqual:request.URL.host]) {
      completionHandler(request);
      return;
    }

    // Prevent redirection from HTTPS to a non-HTTPS URL.
    if ([task.originalRequest.URL.scheme isEqualToString:@"https"]
        && ![request.URL.scheme isEqualToString:@"https"]) {
      completionHandler(nil);
      return;
    }

    // Add the originally used bearer token to a new request.
    NSMutableDictionary *const mutableAllHTTPHeaderFields =
      [NSMutableDictionary dictionaryWithDictionary:request.allHTTPHeaderFields];
    mutableAllHTTPHeaderFields[authorizationKey] = task.originalRequest.allHTTPHeaderFields[authorizationKey];
    NSMutableURLRequest *const mutableRequest = [NSMutableURLRequest requestWithURL:request.URL];
    mutableRequest.allHTTPHeaderFields = mutableAllHTTPHeaderFields;

    // Redirect with the bearer token.
    completionHandler(mutableRequest);
  } else {
    completionHandler(request);
  }
}

- (void)URLSession:(__attribute__((unused)) NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
  NYPLBook *const book = self.taskIdentifierToBook[@(task.taskIdentifier)];
  
  if(!book) {
    // A reset must have occurred.
    return;
  }

  [self.taskIdentifierToRedirectAttempts removeObjectForKey:@(task.taskIdentifier)];

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

#pragma mark -

- (void)deleteLocalContentForBookIdentifier:(NSString *const)identifier
{
  [self deleteLocalContentForBookIdentifier:identifier account:[AccountsManager sharedInstance].currentAccount.uuid];
}

- (void)deleteLocalContentForBookIdentifier:(NSString *const)identifier account:(NSString * const)account
{
  NYPLBook *const book = [[NYPLBookRegistry sharedRegistry] bookForIdentifier:identifier];
  if (!book) {
    NYPLLOG(@"WARNING: Could not find book to delete local content.");
    return;
  }
  
  switch (book.defaultBookContentType) {
    case NYPLBookContentTypeEPUB: {
      NSError *error = nil;
      if(![[NSFileManager defaultManager]
           removeItemAtURL:[self fileURLForBookIndentifier:identifier account:account]
           error:&error]){
        NYPLLOG_F(@"Failed to remove local content for download: %@", error.localizedDescription);
      }
      break;
    }
    case NYPLBookContentTypeAudiobook: {
      NSData *const data = [NSData dataWithContentsOfURL:
                            [self fileURLForBookIndentifier:book.identifier account:account]];
      if (!data) {
        break;
      }
      id const json = NYPLJSONObjectFromData([NSData dataWithContentsOfURL:
                                              [self fileURLForBookIndentifier:book.identifier account:account]]);
        
      NSMutableDictionary *dict = nil;
        
      if ([book.distributor isEqualToString:OverdriveDistributorKey]) {
        dict = [(NSMutableDictionary *)json mutableCopy];
        dict[@"id"] = book.identifier;
      }
      
      [[AudiobookFactory audiobook:dict ?: json] deleteLocalContent];
      break;
    }
    case NYPLBookContentTypePDF: {
      NSError *error = nil;
      if (![[NSFileManager defaultManager]
          removeItemAtURL:[self fileURLForBookIndentifier:identifier account:account]
          error:&error]) {
        NYPLLOG_F(@"Failed to remove local content for download: %@", error.localizedDescription);
      }
      break;
    }
    case NYPLBookContentTypeUnsupported:
      break;
  }
}
  
- (void)returnBookWithIdentifier:(NSString *)identifier
{
  NYPLBook *book = [[NYPLBookRegistry sharedRegistry] bookForIdentifier:identifier];
  NSString *bookTitle = book.title;
  NYPLBookState state = [[NYPLBookRegistry sharedRegistry] stateForIdentifier:identifier];
  BOOL downloaded = state == NYPLBookStateDownloadSuccessful || state == NYPLBookStateUsed;
  if (!book.identifier) {
    [NYPLErrorLogger logUnexpectedNilIdentifier:identifier book:book];
  }

  // Process Adobe Return
#if defined(FEATURE_DRM_CONNECTOR)
  NSString *fulfillmentId = [[NYPLBookRegistry sharedRegistry] fulfillmentIdForIdentifier:identifier];
  if (fulfillmentId && [[AccountsManager sharedInstance] currentAccount].details.needsAuth) {
    NYPLLOG_F(@"Return attempt for book. userID: %@",[[NYPLUserAccount sharedAccount] userID]);
    [[NYPLADEPT sharedInstance] returnLoan:fulfillmentId
                                    userID:[[NYPLUserAccount sharedAccount] userID]
                                  deviceID:[[NYPLUserAccount sharedAccount] deviceID]
                                completion:^(BOOL success, __unused NSError *error) {
                                  if(!success) {
                                    NYPLLOG(@"Failed to return loan via NYPLAdept.");
                                  }
                                }];
  }
#endif

  if (!book.revokeURL) {
    if (downloaded) {
      [self deleteLocalContentForBookIdentifier:identifier];
    }
    [[NYPLBookRegistry sharedRegistry] removeBookForIdentifier:identifier];
    [[NYPLBookRegistry sharedRegistry] save];
  } else {
    [[NYPLBookRegistry sharedRegistry] setProcessing:YES forIdentifier:book.identifier];
    [NYPLOPDSFeed withURL:book.revokeURL completionHandler:^(NYPLOPDSFeed *feed, NSDictionary *error) {

      [[NYPLBookRegistry sharedRegistry] setProcessing:NO forIdentifier:book.identifier];
      
      if(feed && feed.entries.count == 1)  {
        NYPLOPDSEntry *const entry = feed.entries[0];
        if(downloaded) {
          [self deleteLocalContentForBookIdentifier:identifier];
        }
        NYPLBook *returnedBook = [NYPLBook bookWithEntry:entry];
        if(returnedBook) {
          [[NYPLBookRegistry sharedRegistry] updateAndRemoveBook:returnedBook];
        } else {
          NYPLLOG(@"Failed to create book from entry. Book not removed from registry.");
        }
      } else {
        if([error[@"type"] isEqualToString:NYPLProblemDocument.TypeNoActiveLoan]) {
          if(downloaded) {
            [self deleteLocalContentForBookIdentifier:identifier];
          }
          [[NYPLBookRegistry sharedRegistry] removeBookForIdentifier:identifier];
        } else {
          [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSString *formattedMessage = [NSString stringWithFormat:NSLocalizedString(@"ReturnCouldNotBeCompletedFormat", nil), bookTitle];
            UIAlertController *alert = [NYPLAlertUtils
                                        alertWithTitle:@"ReturnFailed"
                                        message:formattedMessage];
            if (error) {
              [NYPLAlertUtils setProblemDocumentWithController:alert document:[NYPLProblemDocument fromDictionary:error] append:YES];
            }
            [NYPLAlertUtils presentFromViewControllerOrNilWithAlertController:alert viewController:nil animated:YES completion:nil];
          }];
        }
      }
    }];
  }
}

- (NYPLMyBooksDownloadInfo *)downloadInfoForBookIdentifier:(NSString *const)bookIdentifier
{
  return self.bookIdentifierToDownloadInfo[bookIdentifier];
}

- (NSURL *)contentDirectoryURL
{
  return [self contentDirectoryURL:[AccountsManager sharedInstance].currentAccount.uuid];
}

- (NSURL *)contentDirectoryURL:(NSString *)account
{
  NSURL *directoryURL = [[DirectoryManager directory:account] URLByAppendingPathComponent:@"content"];
  
  if (directoryURL != nil) {
    NSError *error = nil;
    if(![[NSFileManager defaultManager]
         createDirectoryAtURL:directoryURL
         withIntermediateDirectories:YES
         attributes:nil
         error:&error]) {
      NYPLLOG(@"Failed to create directory.");
      return nil;
    }
  } else {
    NYPLLOG(@"[contentDirectoryURL] nil directory.");
  }
  return directoryURL;
}

- (NSURL *)fileURLForBookIndentifier:(NSString *const)identifier
{
  return [self fileURLForBookIndentifier:identifier account:[AccountsManager sharedInstance].currentAccount.uuid];
}
  
- (NSURL *)fileURLForBookIndentifier:(NSString *const)identifier account:(NSString * const)account
{
  if(!identifier) return nil;
  
  // FIXME: The extension is always "epub" even when the URL refers to content of a different
  // type (e.g. an audiobook). While there's no reason this must change, it's certainly likely
  // to cause confusion for anyone looking at the filesystem.
  return [[[self contentDirectoryURL:account] URLByAppendingPathComponent:[identifier SHA256]]
          URLByAppendingPathExtension:@"epub"];
}

- (void)failDownloadForBook:(NYPLBook *const)book
{
  [[NYPLBookRegistry sharedRegistry]
   addBook:book
   location:nil
   state:NYPLBookStateDownloadFailed
   fulfillmentId:nil
   readiumBookmarks:nil
   genericBookmarks:nil];
  
  dispatch_async(dispatch_get_main_queue(), ^{
    NSString *formattedMessage = [NSString stringWithFormat:NSLocalizedString(@"DownloadCouldNotBeCompletedFormat", nil), book.title];
    UIAlertController *alert = [NYPLAlertUtils alertWithTitle:@"DownloadFailed" message:formattedMessage];
    [NYPLAlertUtils presentFromViewControllerOrNilWithAlertController:alert viewController:nil animated:YES completion:nil];
  });
  
  [self broadcastUpdate];
}

- (void)startBorrowForBook:(NYPLBook *)book
           attemptDownload:(BOOL)shouldAttemptDownload
          borrowCompletion:(void (^)(void))borrowCompletion
{
  [[NYPLBookRegistry sharedRegistry] setProcessing:YES forIdentifier:book.identifier];
  [NYPLOPDSFeed withURL:book.defaultAcquisitionIfBorrow.hrefURL completionHandler:^(NYPLOPDSFeed *feed, NSDictionary *error) {
    [[NYPLBookRegistry sharedRegistry] setProcessing:NO forIdentifier:book.identifier];

    if (error || !feed || feed.entries.count < 1) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (borrowCompletion) {
          borrowCompletion();
          return;
        }

        // create an alert to display for error, feed, or feed count conditions
        NSString *formattedMessage = [NSString stringWithFormat:NSLocalizedString(@"BorrowCouldNotBeCompletedFormat", nil), book.title];
        UIAlertController *alert = [NYPLAlertUtils alertWithTitle:@"BorrowFailed" message:formattedMessage];

        // set different message for special type of error or just add document message for generic error
        if (error) {
          if ([error[@"type"] isEqualToString:NYPLProblemDocument.TypeLoanAlreadyExists]) {
            formattedMessage = [NSString stringWithFormat:NSLocalizedString(@"You have already checked out this loan. You may need to refresh your My Books list to download the title.",
                                                                            comment: @"When book is already checked out on patron's other device(s), they will get this message"), book.title];
            alert = [NYPLAlertUtils alertWithTitle:@"BorrowFailed" message:formattedMessage];
          } else {
            [NYPLAlertUtils setProblemDocumentWithController:alert document:[NYPLProblemDocument fromDictionary:error] append:YES];
          }
        }

        // display the alert
        [NYPLAlertUtils presentFromViewControllerOrNilWithAlertController:alert viewController:nil animated:YES completion:nil];
      }];
      return;
    }

    NYPLBook *book = [NYPLBook bookWithEntry:feed.entries[0]];

    if(!book) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (borrowCompletion) {
          borrowCompletion();
          return;
        }
        NSString *formattedMessage = [NSString stringWithFormat:NSLocalizedString(@"BorrowCouldNotBeCompletedFormat", nil), book.title];
        UIAlertController *alert = [NYPLAlertUtils alertWithTitle:@"BorrowFailed" message:formattedMessage];
        [NYPLAlertUtils presentFromViewControllerOrNilWithAlertController:alert viewController:nil animated:YES completion:nil];
      }];
      return;
    }

    [[NYPLBookRegistry sharedRegistry]
     addBook:book
     location:nil
     state:NYPLBookStateDownloadNeeded
     fulfillmentId:nil
     readiumBookmarks:nil
     genericBookmarks:nil];

    if(borrowCompletion) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        borrowCompletion();
        return;
      }];
    }

    if (shouldAttemptDownload) {
      [book.defaultAcquisition.availability
       matchUnavailable:nil
       limited:^(__unused NYPLOPDSAcquisitionAvailabilityLimited *_Nonnull limited) {
         [[NYPLMyBooksDownloadCenter sharedDownloadCenter] startDownloadForBook:book];
       }
       unlimited:^(__unused NYPLOPDSAcquisitionAvailabilityUnlimited *_Nonnull unlimited) {
         [[NYPLMyBooksDownloadCenter sharedDownloadCenter] startDownloadForBook:book];
       }
       reserved:nil
       ready:^(__unused NYPLOPDSAcquisitionAvailabilityReady *_Nonnull ready) {
         [[NYPLMyBooksDownloadCenter sharedDownloadCenter] startDownloadForBook:book];
       }];
    }
  }];
}

- (void)startDownloadForBook:(NYPLBook *const)book
{
  NYPLBookState state = [[NYPLBookRegistry sharedRegistry]
                         stateForIdentifier:book.identifier];
  
  BOOL loginRequired = YES;
  
  switch(state) {
    case NYPLBookStateUnregistered:
      if(!book.defaultAcquisitionIfBorrow && (book.defaultAcquisitionIfOpenAccess || ![[AccountsManager sharedInstance] currentAccount].details.needsAuth)) {
        [[NYPLBookRegistry sharedRegistry]
         addBook:book
         location:nil
         state:NYPLBookStateDownloadNeeded
         fulfillmentId:nil
         readiumBookmarks:nil
         genericBookmarks:nil];
        state = NYPLBookStateDownloadNeeded;
        loginRequired = NO;
      }
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
      // fallthrough
    case NYPLBookStateUnsupported:
      NYPLLOG(@"Ignoring nonsensical download request.");
      return;
  }
  
  if([NYPLUserAccount sharedAccount].hasBarcodeAndPIN || !loginRequired) {
    if(state == NYPLBookStateUnregistered || state == NYPLBookStateHolding) {
      // Check out the book
      [self startBorrowForBook:book attemptDownload:YES borrowCompletion:nil];
    } else if ([book.distributor isEqualToString:OverdriveDistributorKey]) {
      NSURL *URL = book.defaultAcquisition.hrefURL;
        
      [[OverdriveAPIExecutor shared] fulfillBookWithUrlString:URL.absoluteString
                                                     username:[[NYPLUserAccount sharedAccount] barcode]
                                                          PIN:[[NYPLUserAccount sharedAccount] PIN]
                                                   completion:^(NSDictionary<NSString *,id> * _Nullable responseHeader, NSError * _Nullable _) {
        if (responseHeader[@"X-Overdrive-Scope"] && responseHeader[@"Location"]) {
            
            [[OverdriveAPIExecutor shared] refreshPatronTokenWithKey:NYPLSecrets.overdriveClientKey secret:NYPLSecrets.overdriveClientSecret username:[[NYPLUserAccount sharedAccount] barcode] PIN:[[NYPLUserAccount sharedAccount] PIN] scope:responseHeader[@"X-Overdrive-Scope"] completion:^(NSError * _Nullable error) {
              if (!error) {
                NSURLRequest *request = [[OverdriveAPIExecutor shared] getManifestRequestWithUrlString:responseHeader[@"Location"]];
                [self addDownloadTaskWithRequest:request book:book];
              }
            }];
        }
      }];
        
    } else {
      // Actually download the book.
      NSURL *URL = book.defaultAcquisition.hrefURL;
      NSURLRequest *const request = [NSURLRequest requestWithURL:URL];
        
      if(!request.URL) {
        // Originally this code just let the request fail later on, but apparently resuming an
        // NSURLSessionDownloadTask created from a request with a nil URL pathetically results in a
        // segmentation fault.
        NYPLLOG(@"Aborting request with invalid URL.");
        [self failDownloadForBook:book];
        return;
      }
      
      [self addDownloadTaskWithRequest:request book:book];
    }

  } else {
    [NYPLAccountSignInViewController
     requestCredentialsUsingExistingBarcode:NO
     completionHandler:^{
       [[NYPLMyBooksDownloadCenter sharedDownloadCenter] startDownloadForBook:book];
     }];
  }
}

- (void)addDownloadTaskWithRequest:(NSURLRequest *)request
                              book:(NYPLBook *)book {
  if (book == nil) {
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
   state:NYPLBookStateDownloading
   fulfillmentId:nil
   readiumBookmarks:nil
   genericBookmarks:nil];
  
  // It is important to issue this immediately because a previous download may have left the
  // progress for the book at greater than 0.0 and we do not want that to be temporarily shown to
  // the user. As such, calling |broadcastUpdate| is not appropriate due to the delay.
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLMyBooksDownloadCenterDidChangeNotification
   object:self];
}

- (void)cancelDownloadForBookIdentifier:(NSString *)identifier
{
  
  NYPLMyBooksDownloadInfo *info = [self downloadInfoForBookIdentifier:identifier];
  
  if (info) {
    #if defined(FEATURE_DRM_CONNECTOR)
      if (info.rightsManagement == NYPLMyBooksDownloadRightsManagementAdobe) {
          [[NYPLADEPT sharedInstance] cancelFulfillmentWithTag:identifier];
        return;
      }
    #endif
    
    [info.downloadTask
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

- (void)deleteAudiobooksForAccount:(NSString * const)account
{
  [[NYPLBookRegistry sharedRegistry]
   performUsingAccount:account
   block:^{
     NSArray<NSString *> const *books = [[NYPLBookRegistry sharedRegistry] allBooks];
     for (NYPLBook *const book in books) {
       if (book.defaultBookContentType == NYPLBookContentTypeAudiobook) {
         [[NYPLMyBooksDownloadCenter sharedDownloadCenter]
          deleteLocalContentForBookIdentifier:book.identifier
          account:account];
       }
     }
   }];
}

- (void)reset:(NSString *)account
{
  if ([[AccountsManager shared].currentAccount.uuid isEqualToString:account])
  {
    [self reset];
  }
  else
  {
    [self deleteAudiobooksForAccount:account];
    [[NSFileManager defaultManager]
     removeItemAtURL:[self contentDirectoryURL:account]
     error:NULL];
  }
}


- (void)reset
{
  [self deleteAudiobooksForAccount:[AccountsManager sharedInstance].currentAccount.uuid];
  
  for(NYPLMyBooksDownloadInfo *const info in [self.bookIdentifierToDownloadInfo allValues]) {
    [info.downloadTask cancelByProducingResumeData:^(__unused NSData *resumeData) {}];
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

- (BOOL)moveDownloadedFileAtURL:(NSURL *)location
                           book:(NYPLBook *)book
{
  BOOL success = [[NSFileManager defaultManager] replaceItemAtURL:[self fileURLForBookIndentifier:book.identifier]
                                                    withItemAtURL:location
                                                   backupItemName:nil
                                                          options:NSFileManagerItemReplacementUsingNewMetadataOnly
                                                 resultingItemURL:nil
                                                            error:nil];
  
  if(success) {
    [[NYPLBookRegistry sharedRegistry] setState:NYPLBookStateDownloadSuccessful forIdentifier:book.identifier];
    [[NYPLBookRegistry sharedRegistry] save];
  }

  return success;
}

#if defined(FEATURE_DRM_CONNECTOR)
  
#pragma mark NYPLADEPTDelegate
  
- (void)adept:(__attribute__((unused)) NYPLADEPT *)adept didUpdateProgress:(double)progress tag:(NSString *)tag
{
  self.bookIdentifierToDownloadInfo[tag] =
  [[self downloadInfoForBookIdentifier:tag] withDownloadProgress:progress];

  [self broadcastUpdate];
}

- (void)adept:(__attribute__((unused)) NYPLADEPT *)adept didFinishDownload:(BOOL)success toURL:(NSURL *)URL fulfillmentID:(NSString *)fulfillmentID isReturnable:(BOOL)isReturnable rightsData:(NSData *)rightsData tag:(NSString *)tag error:(__attribute__((unused)) NSError *)error
{
  NYPLBook *const book = [[NYPLBookRegistry sharedRegistry] bookForIdentifier:tag];

  if(success) {
    [[NSFileManager defaultManager]
     removeItemAtURL:[self fileURLForBookIndentifier:book.identifier]
     error:NULL];

    if (![self fileURLForBookIndentifier:book.identifier]) {
      [self failDownloadForBook:book];
      [NYPLErrorLogger
       logMissingFileURLAfterDownloadingBook:book
       message:@"fileURLForBookIndentifier returned nil, so no destination to copy file to."];
      return;
    }
    
    // This needs to be a copy else the Adept connector will explode when it tries to delete the
    // temporary file.
    success = [[NSFileManager defaultManager]
               copyItemAtURL:URL
               toURL:[self fileURLForBookIndentifier:book.identifier]
               error:NULL];
  }

  if(!success) {
    [self failDownloadForBook:book];
    return;
  }

  //
  // The rights data are stored in {book_filename}_rights.xml,
  // alongside with the book because Readium+DRM expect this when
  // opening the EPUB 3.
  // See Container::Open(const string& path) in container.cpp.
  //
  if(![rightsData writeToFile:[[[self fileURLForBookIndentifier:book.identifier] path]
                               stringByAppendingString:@"_rights.xml"]
                   atomically:YES]) {
    NYPLLOG(@"Failed to store rights data.");
  }
  
  if(isReturnable && fulfillmentID) {
    [[NYPLBookRegistry sharedRegistry]
     setFulfillmentId:fulfillmentID forIdentifier:book.identifier];
  }

  [[NYPLBookRegistry sharedRegistry]
   setState:NYPLBookStateDownloadSuccessful forIdentifier:book.identifier];
  
  [[NYPLBookRegistry sharedRegistry] save];

  [self broadcastUpdate];
}
  
- (void)adept:(__attribute__((unused)) NYPLADEPT *)adept didCancelDownloadWithTag:(NSString *)tag
{
  [[NYPLBookRegistry sharedRegistry]
   setState:NYPLBookStateDownloadNeeded forIdentifier:tag];

  [self broadcastUpdate];
}

- (void)didIgnoreFulfillmentWithNoAuthorizationPresent
{
  [NYPLAccountSignInViewController authorizeUsingExistingBarcodeAndPinWithCompletionHandler:nil];
}

#endif

@end
