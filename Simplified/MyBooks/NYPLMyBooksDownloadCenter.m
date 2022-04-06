#if FEATURE_AUDIOBOOKS
@import NYPLAudiobookToolkit;
#endif

#if FEATURE_OVERDRIVE_AUTH
@import OverdriveProcessor;
#endif

#import "NSString+NYPLStringAdditions.h"
#import "NYPLAccountSignInViewController.h"
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

#if defined(LCP)
#import <ReadiumLCP/ReadiumLCP-Swift.h>
#endif

#if defined(AXIS)
@interface NYPLMyBooksDownloadCenter () <NYPLBookDownloadBroadcasting>
@property (nonatomic) NSMutableDictionary<NSString *, NYPLAxisBookDownloadAdapter *> *bookIdentifierToAxisAdapter;
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
@property (nonatomic) NYPLReauthenticator *reauthenticator;
@property (nonatomic) NYPLAudiobookDownloader *audiobookDownloader;

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
  
#if FEATURE_AUDIOBOOKS
  self.audiobookDownloader = [[NYPLAudiobookDownloader alloc] init];
  self.audiobookDownloader.delegate = (id)self;
#endif
  
  NSURLSessionConfiguration *const configuration =
    [NSURLSessionConfiguration ephemeralSessionConfiguration];
  
#if defined(AXIS)
  self.bookIdentifierToAxisAdapter = [NSMutableDictionary dictionary];
#endif
  
  self.bookIdentifierToDownloadInfo = [NSMutableDictionary dictionary];
  self.bookIdentifierToDownloadProgress = [NSMutableDictionary dictionary];
  self.bookIdentifierToDownloadTask = [NSMutableDictionary dictionary];
  
  self.session = [NSURLSession
                  sessionWithConfiguration:configuration
                  delegate:self
                  delegateQueue:[NSOperationQueue mainQueue]];
  
  self.taskIdentifierToBook = [NSMutableDictionary dictionary];
  self.taskIdentifierToRedirectAttempts = [NSMutableDictionary dictionary];
  self.reauthenticator = [[NYPLReauthenticator alloc] init];
  
  return self;
}

#pragma mark - NSURLSessionDownloadDelegate

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

/// This appears to be called only once per book download for Adobe and Axis.
/// For Bearer Token requests this is called multiple times.
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
    if([downloadTask.response.MIMEType isEqualToString:ContentTypeAdobeAdept]) {
      self.bookIdentifierToDownloadInfo[book.identifier] =
      [[self downloadInfoForBookIdentifier:book.identifier]
       withRightsManagement:NYPLMyBooksDownloadRightsManagementAdobe];
    } else if ([downloadTask.response.MIMEType isEqualToString:ContentTypeAxis360]) {
      self.bookIdentifierToDownloadInfo[book.identifier] =
      [[self downloadInfoForBookIdentifier:book.identifier]
       withRightsManagement:NYPLMyBooksDownloadRightsManagementAxis];
#if LCP
    } else if([downloadTask.response.MIMEType isEqualToString:ContentTypeReadiumLCP]) {
        self.bookIdentifierToDownloadInfo[book.identifier] =
        [[self downloadInfoForBookIdentifier:book.identifier]
         withRightsManagement:NYPLMyBooksDownloadRightsManagementLCP];
#endif
    } else if([downloadTask.response.MIMEType isEqualToString:ContentTypeEpubZip]) {
      self.bookIdentifierToDownloadInfo[book.identifier] =
      [[self downloadInfoForBookIdentifier:book.identifier]
       withRightsManagement:NYPLMyBooksDownloadRightsManagementNone];
    } else if ([downloadTask.response.MIMEType isEqualToString:ContentTypeBearerToken]) {
      self.bookIdentifierToDownloadInfo[book.identifier] =
        [[self downloadInfoForBookIdentifier:book.identifier]
         withRightsManagement:NYPLMyBooksDownloadRightsManagementSimplifiedBearerTokenJSON];
#if FEATURE_AUDIOBOOKS && FEATURE_OVERDRIVE_AUTH
    } else if ([downloadTask.response.MIMEType isEqualToString:ContentTypeOverdriveAudiobookActual]) {
      self.bookIdentifierToDownloadInfo[book.identifier] =
      [[self downloadInfoForBookIdentifier:book.identifier]
       withRightsManagement:NYPLMyBooksDownloadRightsManagementOverdriveManifestJSON];
#endif
    } else if ([NYPLOPDSAcquisitionPath.supportedTypes containsObject:downloadTask.response.MIMEType]) {
      NYPLMyBooksDownloadInfo *info = [[self downloadInfoForBookIdentifier:book.identifier]
                                       withRightsManagement:NYPLMyBooksDownloadRightsManagementNone];
      if (info) {
        self.bookIdentifierToDownloadInfo[book.identifier] = info;
      }
    } else {
      NYPLLOG(@"Authentication might be needed after all");
      [downloadTask cancel];
      [[NYPLBookRegistry sharedRegistry] setState:NYPLBookStateDownloadFailed forIdentifier:book.identifier];
      [self broadcastUpdate:book.identifier];
      return;
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
      
      [self broadcastUpdate:book.identifier];
    }
  }
}

- (void)URLSession:(__attribute__((unused)) NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *const)downloadTask
didFinishDownloadingToURL:(NSURL *const)tmpSavedFileURL
{
  NYPLBook *const book = self.taskIdentifierToBook[@(downloadTask.taskIdentifier)];
  
  if(!book) {
    // A reset must have occurred.
    return;
  }

  [self.taskIdentifierToRedirectAttempts removeObjectForKey:@(downloadTask.taskIdentifier)];
  
  BOOL failureRequiringAlert = NO;
  NSError *failureError = downloadTask.error;
  NYPLProblemDocument *problemDoc = nil;
  NYPLMyBooksDownloadRightsManagement rights = [self downloadInfoForBookIdentifier:book.identifier].rightsManagement;

  if ([downloadTask.response isProblemDocument]) {
    NSError *problemDocumentParseError = nil;
    NSData *problemDocData = [NSData dataWithContentsOfURL:tmpSavedFileURL];
    problemDoc = [NYPLProblemDocument fromData:problemDocData
                                         error:&problemDocumentParseError];
    if (problemDocumentParseError) {
      [NYPLErrorLogger
       logProblemDocumentParseError:problemDocumentParseError
       problemDocumentData:problemDocData
       url:tmpSavedFileURL
       summary:[NSString stringWithFormat:@"Error parsing problem doc downloading %@ book", book.distributor]
       metadata:@{ @"book": [book loggableShortString] }];
    }

    [[NSFileManager defaultManager] removeItemAtURL:tmpSavedFileURL error:NULL];
    failureRequiringAlert = YES;
  }

  if (![book canCompleteDownloadWithContentType:downloadTask.response.MIMEType]) {
    [[NSFileManager defaultManager] removeItemAtURL:tmpSavedFileURL error:NULL];
    failureRequiringAlert = YES;
  }

  if (failureRequiringAlert) {
    [self logBookDownloadFailure:book
                          reason:@"Download Error"
                    downloadTask:downloadTask
                        metadata:@{@"problemDocument":
                                     problemDoc.dictionaryValue ?: @"N/A"}];
  } else {
    [[NYPLProblemDocumentCacheManager sharedInstance] clearCachedDocForBookIdentifier:book.identifier];

    switch(rights) {
      case NYPLMyBooksDownloadRightsManagementUnknown:
        [self logBookDownloadFailure:book
                              reason:@"Unknown rights management"
                        downloadTask:downloadTask
                            metadata:nil];
        failureRequiringAlert = YES;
        break;
      case NYPLMyBooksDownloadRightsManagementAdobe: {
#if defined(FEATURE_DRM_CONNECTOR)
        NSData *ACSMData = [NSData dataWithContentsOfURL:tmpSavedFileURL];
        NSString *PDFString = @">application/pdf</dc:format>";
        if([[[NSString alloc] initWithData:ACSMData encoding:NSUTF8StringEncoding] containsString:PDFString]) {
          NSString *msg = [NSString
                           stringWithFormat:NSLocalizedString(@"PDFNotSupportedFormatStr", nil),
                           book.title];
          failureError = [NSError errorWithDomain:NYPLErrorLogger.clientDomain
                                             code:NYPLErrorCodeIgnore
                                         userInfo:@{ NSLocalizedDescriptionKey: msg }];
          [self logBookDownloadFailure:book
                                reason:@"Received PDF for AdobeDRM rights"
                          downloadTask:downloadTask
                              metadata:nil];
          failureRequiringAlert = YES;
        } else {
          NYPLLOG_F(@"Download finished. Fulfilling with userID: %@",[[NYPLUserAccount sharedAccount] userID]);
          [[NYPLADEPT sharedInstance]
           fulfillWithACSMData:ACSMData
           tag:book.identifier
           userID:[[NYPLUserAccount sharedAccount] userID]
           deviceID:[[NYPLUserAccount sharedAccount] deviceID]
           completion:^(NSError *fulfillError) {
            if (fulfillError) {
              [self logBookDownloadFailure:book
                                    reason:@"Unable to fulfill loan with Adobe"
                              downloadTask:downloadTask
                                  metadata:nil];
              [self failDownloadWithAlertForBook:book];
            }
          }];
        }
#endif
        break;
      }
      case NYPLMyBooksDownloadRightsManagementLCP: {
        [self fulfillLCPLicense:tmpSavedFileURL forBook:book downloadTask:downloadTask];
        break;
      }
      case NYPLMyBooksDownloadRightsManagementSimplifiedBearerTokenJSON: {
        NSData *const data = [NSData dataWithContentsOfURL:tmpSavedFileURL];
        if (!data) {
          [self logBookDownloadFailure:book
                                reason:@"No Simplified Bearer Token data available on disk"
                          downloadTask:downloadTask
                              metadata:nil];
          [self failDownloadWithAlertForBook:book];
          break;
        }

        NSDictionary *const dictionary = NYPLJSONObjectFromData(data);
        if (![dictionary isKindOfClass:[NSDictionary class]]) {
          [self logBookDownloadFailure:book
                                reason:@"Unable to deserialize Simplified Bearer Token data"
                          downloadTask:downloadTask
                              metadata:nil];
          [self failDownloadWithAlertForBook:book];
          break;
        }

        NYPLMyBooksSimplifiedBearerToken *const simplifiedBearerToken =
          [NYPLMyBooksSimplifiedBearerToken simplifiedBearerTokenWithDictionary:dictionary];

        if (!simplifiedBearerToken) {
          [self logBookDownloadFailure:book
                                reason:@"No Simplified Bearer Token in deserialized data"
                          downloadTask:downloadTask
                              metadata:nil];
          [self failDownloadWithAlertForBook:book];
          break;
        }

        // execute bearer token request
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
        failureRequiringAlert = ![self replaceBook:book
                                     withFileAtURL:tmpSavedFileURL
                                   forDownloadTask:downloadTask];
        break;
      }
      case NYPLMyBooksDownloadRightsManagementNone: {
        failureRequiringAlert = ![self moveFileAtURL:tmpSavedFileURL
                                toDestinationForBook:book
                                     forDownloadTask:downloadTask];
        break;
      }
      case NYPLMyBooksDownloadRightsManagementAxis: {
#if defined(AXIS)
        
        NYPLAxisBookDownloadAdapter *adapter = [[NYPLAxisBookDownloadAdapter alloc]
                                                initWithDownloadTask:downloadTask
                                                book:book
                                                downloadBroadcaster:self
                                                fileURL:tmpSavedFileURL];
        
        [self.bookIdentifierToAxisAdapter setValue:adapter forKey:book.identifier];
        [adapter downloadBook];
#endif
        break;
      }
        
    }
  }
  
  if (failureRequiringAlert) {
    dispatch_async(dispatch_get_main_queue(), ^{
      // re-auth so that when we "Try again" we won't fail for the same reason
      [self.reauthenticator authenticateIfNeeded:NYPLUserAccount.sharedAccount
                               afterHTTPResponse:downloadTask.response
                             withProblemDocument:problemDoc
                        authenticationCompletion:nil];

      [self alertForProblemDocument:problemDoc error:failureError book:book];
    });
    
    [[NYPLBookRegistry sharedRegistry]
     setState:NYPLBookStateDownloadFailed
     forIdentifier:book.identifier];
  }
  
#if FEATURE_AUDIOBOOKS
  if (book.defaultBookContentType == NYPLBookContentTypeAudiobook) {
    [AudiobookManifestAdapter transformAudiobookManifestWithBook:book
                                                      completion:^(NSDictionary<NSString *,id> * _Nullable json,
                                                                   id<DRMDecryptor> _Nullable decryptor,
                                                                   enum AudiobookManifestError error) {
      if (error == AudiobookManifestErrorNone) {
        // Create audiobook
        id<Audiobook> const audiobook = [AudiobookFactory audiobook:json decryptor:decryptor];
        
        if (!audiobook) {
          NYPLLOG(@"Audiobook initiate failed");
          // TODO: Handle Error
          [self broadcastUpdate:book.identifier];
          return;
        }
        AudiobookMetadata *metadata = [[AudiobookMetadata alloc] initWithTitle:book.title
                                                                       authors:@[book.authors]];
        
        DefaultAudiobookManager *manager = [[DefaultAudiobookManager alloc] initWithMetadata:metadata
                                                                                   audiobook:audiobook];
        
        [[NYPLBookRegistry sharedRegistry]
         setState:NYPLBookStateDownloading
         forIdentifier:book.identifier];
        
        [self downloadProgressDidUpdateTo:0 forBookIdentifier:book.identifier];
        
        [self.audiobookDownloader downloadAudiobookForBookID:book.identifier
                                            audiobookManager:manager];
      } else {
        NYPLLOG(@"Audiobook corrupted/unsupported");
        // TODO: Handle Error
        [self broadcastUpdate:book.identifier];
      }
    }];
    return;
  }
#else
  [self broadcastUpdate:book.identifier];
#endif
}

#pragma mark - NSURLSessionTaskDelegate

// As with the NSURLSessionDownloadDelegate methods, we need to be mindful of resets for the task
// delegate methods too.

- (void)URLSession:(__attribute__((unused)) NSURLSession *)session
              task:(__attribute__((unused)) NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *const)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                             NSURLCredential *credential))completionHandler
{
  NYPLBasicAuth *handler = [[NYPLBasicAuth alloc] initWithCredentialsProvider:NYPLUserAccount.sharedAccount];
  [handler handleChallenge:challenge completion:completionHandler];
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
    [self logBookDownloadFailure:book
                          reason:@"networking error"
                    downloadTask:task
                        metadata:@{
                          @"urlSessionError": error
                        }];
    [self failDownloadWithAlertForBook:book];
  }
}

#pragma mark - File Management

- (BOOL)moveFileAtURL:(NSURL *)sourceLocation
 toDestinationForBook:(NYPLBook *)book
      forDownloadTask:(NSURLSessionDownloadTask *)downloadTask
{
  NSError *removeError = nil, *moveError = nil;
  NSURL *finalFileURL = [self fileURLForBookIndentifier:book.identifier];

  [[NSFileManager defaultManager]
   removeItemAtURL:finalFileURL
   error:&removeError];

  BOOL success = [[NSFileManager defaultManager]
                  moveItemAtURL:sourceLocation
                  toURL:finalFileURL
                  error:&moveError];

  if (success) {
    [[NYPLBookRegistry sharedRegistry]
     setState:NYPLBookStateDownloadSuccessful forIdentifier:book.identifier];
    [[NYPLBookRegistry sharedRegistry] save];
  } else if (moveError) {
    [self logBookDownloadFailure:book
                          reason:@"Couldn't move book to final disk location"
                    downloadTask:downloadTask
                        metadata:@{
      @"moveError": moveError,
      @"removeError": removeError.debugDescription ?: @"N/A",
      @"sourceLocation": sourceLocation ?: @"N/A",
      @"finalFileURL": finalFileURL ?: @"N/A",
    }];
  }

  return success;
}

- (BOOL)replaceBook:(NYPLBook *)book
      withFileAtURL:(NSURL *)sourceLocation
    forDownloadTask:(NSURLSessionDownloadTask *)downloadTask
{
  NSError *replaceError = nil;
  NSURL *destURL = [self fileURLForBookIndentifier:book.identifier];
  BOOL success = [[NSFileManager defaultManager] replaceItemAtURL:destURL
                                                    withItemAtURL:sourceLocation
                                                   backupItemName:nil
                                                          options:NSFileManagerItemReplacementUsingNewMetadataOnly
                                                 resultingItemURL:nil
                                                            error:&replaceError];

  if(success) {
    [[NYPLBookRegistry sharedRegistry] setState:NYPLBookStateDownloadSuccessful forIdentifier:book.identifier];
    [[NYPLBookRegistry sharedRegistry] save];
  } else {
    [self logBookDownloadFailure:book
                          reason:@"Couldn't replace downloaded book"
                    downloadTask:downloadTask
                        metadata:@{
      @"replaceError": replaceError ?: @"N/A",
      @"destinationFileURL": destURL ?: @"N/A",
      @"sourceFileURL": sourceLocation ?: @"N/A",
    }];
  }
#if defined(AXIS)
  [self.bookIdentifierToAxisAdapter removeObjectForKey:book.identifier];
#endif

  return success;
}

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
  
  NSURL *bookURL = [self fileURLForBookIndentifier:identifier account:account];
  
  switch (book.defaultBookContentType) {
    case NYPLBookContentTypeEPUB: {
      NYPLMyBooksDownloadInfo *info = [self downloadInfoForBookIdentifier:book.identifier];
      if (info.rightsManagement == NYPLMyBooksDownloadRightsManagementAxis) {
        // We're deleting path extension because with AXIS books, we don't
        // get an epub file (?? -ep). Instead, we get a file with book_vault_id
        // and isbn key. From that file, we download all the files associated
        // with the book (xhtml, jpg, xml etc).
        bookURL = bookURL.URLByDeletingPathExtension;
      }

      NSError *error = nil;
      if(![[NSFileManager defaultManager] removeItemAtURL:bookURL error:&error]){
        NYPLLOG_F(@"Failed to remove local content for download: %@", error.localizedDescription);
      }
      break;
    }
    case NYPLBookContentTypePDF: {
      NSError *error = nil;
      if (![[NSFileManager defaultManager] removeItemAtURL:bookURL error:&error]) {
        NYPLLOG_F(@"Failed to remove local content for download: %@", error.localizedDescription);
      }
      break;
    }
    case NYPLBookContentTypeAudiobook:
#if FEATURE_AUDIOBOOKS
      [self deleteLocalContentForAudiobook:book atURL:bookURL];
      break;
#endif
    case NYPLBookContentTypeUnsupported:
      break;
  }
}

#if FEATURE_AUDIOBOOKS

/// Delete downloaded audiobook content
/// @param book Audiobook
/// @param bookURL Location of the book
- (void)deleteLocalContentForAudiobook:(NYPLBook *)book atURL:(NSURL *)bookURL
{
  NSData *const data = [NSData dataWithContentsOfURL:bookURL];

  if (!data) {
    return;
  }
  id const json = NYPLJSONObjectFromData([NSData dataWithContentsOfURL:bookURL]);
  
  NSMutableDictionary *dict = nil;
  
#if FEATURE_OVERDRIVE_AUTH
  if ([book.distributor isEqualToString:OverdriveAPI.distributorKey]) {
    dict = [(NSMutableDictionary *)json mutableCopy];
    dict[@"id"] = book.identifier;
  }
#endif
  
#if defined(LCP)
  if ([LCPAudiobooks canOpenBook:book]) {
    LCPAudiobooks *lcpAudiobooks = [[LCPAudiobooks alloc] initFor:bookURL];
    [lcpAudiobooks contentDictionaryWithCompletion:^(NSDictionary * _Nullable dict, NSError * _Nullable error) {
      if (error) {
        // LCPAudiobooks logs this error
        return;
      }
      if (dict) {
        // Delete decrypted content for the book
        NSMutableDictionary *mutableDict = [dict mutableCopy];
        [[AudiobookFactory audiobook:mutableDict] deleteLocalContent];
      }
    }];
    // Delete LCP book file
    if ([[NSFileManager defaultManager] fileExistsAtPath:bookURL.path]) {
      NSError *error = nil;
      [[NSFileManager defaultManager] removeItemAtURL:bookURL error:&error];
      if (error) {
        [NYPLErrorLogger logError:error
                          summary:@"Failed to delete LCP audiobook local content"
                         metadata:@{ @"book": [book loggableShortString] }];
      }
    }
  } else {
    // Not an LCP book
    [[AudiobookFactory audiobook:dict ?: json] deleteLocalContent];
  }
#else
  [[AudiobookFactory audiobook:dict ?: json] deleteLocalContent];
#endif//LCP
}

#endif//FEATURE_AUDIOBOOKS

- (NSURL *)contentDirectoryURL
{
  return [self contentDirectoryURL:[AccountsManager sharedInstance].currentAccount.uuid];
}

- (NSURL *)contentDirectoryURL:(NSString *)account
{
  NSURL *directoryURL = [[NYPLBookContentMetadataFilesHelper directoryFor:account] URLByAppendingPathComponent:@"content"];
  NYPLLOG_F(@"Book content directory URL: %@", directoryURL);

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

/// Path extension depending on book type
/// @param book `NYPLBook` book
- (NSString *)pathExtensionForBook:(NYPLBook *)book
{
#if FEATURE_AUDIOBOOKS && LCP
  if ([LCPAudiobooks canOpenBook:book]) {
    return @"lcpa";
  }
#endif
  // FIXME: The extension is always "epub" even when the URL refers to content of a different
  // type (e.g. an audiobook). While there's no reason this must change, it's certainly likely
  // to cause confusion for anyone looking at the filesystem.
  return @"epub";
}

- (NSURL *)fileURLForBookIndentifier:(NSString *const)identifier
{
  return [self fileURLForBookIndentifier:identifier account:[AccountsManager sharedInstance].currentAccount.uuid];
}
  
- (NSURL *)fileURLForBookIndentifier:(NSString *const)identifier account:(NSString * const)account
{
  if(!identifier) return nil;
  NYPLBook *book = [[NYPLBookRegistry sharedRegistry] bookForIdentifier:identifier];
  NSString *pathExtension = [self pathExtensionForBook:book];
  return [[[self contentDirectoryURL:account] URLByAppendingPathComponent:[identifier SHA256]]
          URLByAppendingPathExtension:pathExtension];
}

- (void)deleteAudiobooksForAccount:(NSString * const)account
{
  [[NYPLBookRegistry sharedRegistry]
   performUsingAccount:account
   block:^{
    NSArray<NSString *> const *books = [[NYPLBookRegistry sharedRegistry] allBooks];
    for (NYPLBook *const book in books) {
      if (book.defaultBookContentType == NYPLBookContentTypeAudiobook) {
        [self deleteLocalContentForBookIdentifier:book.identifier
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

  [self broadcastUpdate:@""];
}

#pragma mark - Download Logic

- (NYPLMyBooksDownloadInfo *)downloadInfoForBookIdentifier:(NSString *const)bookIdentifier
{
  return self.bookIdentifierToDownloadInfo[bookIdentifier];
}

- (void)startBorrowForBook:(NYPLBook *)book
           attemptDownload:(BOOL)shouldAttemptDownload
          borrowCompletion:(void (^)(void))borrowCompletion
{
  [[NYPLBookRegistry sharedRegistry] setProcessing:YES forIdentifier:book.identifier];
  [NYPLOPDSFeedFetcher fetchOPDSFeedWithUrl:book.defaultAcquisitionIfBorrow.hrefURL
                            networkExecutor:[NYPLNetworkExecutor shared]
                           shouldResetCache:NO
                                 completion:^(NYPLOPDSFeed * _Nullable feed, NSDictionary<NSString *,id> * _Nullable errorDict) {
    [[NYPLBookRegistry sharedRegistry] setProcessing:NO forIdentifier:book.identifier];

    if (errorDict || !feed || feed.entries.count < 1) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (borrowCompletion) {
          borrowCompletion();
          return;
        }

        // create an alert to display for error, feed, or feed count conditions
        NSString *formattedMessage = [NSString stringWithFormat:NSLocalizedString(@"BorrowCouldNotBeCompletedFormat", nil), book.title];
        UIAlertController *alert = [NYPLAlertUtils alertWithTitle:@"BorrowFailed" message:formattedMessage];

        // set different message for special type of error or just add document message for generic error
        if (errorDict) {
          if ([errorDict[@"type"] isEqualToString:NYPLProblemDocument.TypeLoanAlreadyExists]) {
            formattedMessage = [NSString stringWithFormat:NSLocalizedString(@"You have already checked out this loan. You may need to refresh your My Books list to download the title.",
                                                                            comment: @"When book is already checked out on patron's other device(s), they will get this message"), book.title];
            alert = [NYPLAlertUtils alertWithTitle:@"BorrowFailed" message:formattedMessage];
          } else if ([errorDict[@"type"] isEqualToString:NYPLProblemDocument.TypeInvalidCredentials]) {
            NYPLLOG(@"Invalid credentials problem when borrowing a book, present sign in VC");
            __weak __auto_type wSelf = self;
            [self.reauthenticator authenticateIfNeededUsingExistingCredentials:NO
                                                      authenticationCompletion:^{
              [wSelf startDownloadForBook:book];
            }];
            return;
          } else {
            [NYPLAlertUtils setProblemDocumentWithController:alert document:[NYPLProblemDocument fromDictionary:errorDict] append:NO];
          }
        }

        // display the alert
        [NYPLAlertUtils presentFromViewControllerOrNilWithAlertController:alert viewController:nil animated:YES completion:nil];
      }];
      return;
    }
    // after borrowing this book now has [book defaultAcquisitionIfBorrow] == nil
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
  [self startDownloadForBook:book withRequest:nil];
}

- (void)startDownloadForBook:(NYPLBook *const)book withRequest:(NSURLRequest *)initedRequest
{
  NYPLBookState state = [[NYPLBookRegistry sharedRegistry]
                         stateForIdentifier:book.identifier];

  BOOL loginRequired = NYPLUserAccount.sharedAccount.requiresUserAuthentication;

  switch(state) {
    case NYPLBookStateUnregistered:
      if(!book.defaultAcquisitionIfBorrow
         && (book.defaultAcquisitionIfOpenAccess || !loginRequired)) {

        [[NYPLBookRegistry sharedRegistry]
         addBook:book
         location:nil
         state:NYPLBookStateDownloadNeeded
         fulfillmentId:nil
         readiumBookmarks:nil
         genericBookmarks:nil];
        state = NYPLBookStateDownloadNeeded;
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
    case NYPLBookStateSAMLStarted:
      break;
    case NYPLBookStateDownloadSuccessful:
      // fallthrough
    case NYPLBookStateUsed:
      // fallthrough
    case NYPLBookStateUnsupported:
      NYPLLOG(@"Ignoring nonsensical download request.");
      return;
  }
  
  if([NYPLUserAccount sharedAccount].hasCredentials || !loginRequired) {
    if(state == NYPLBookStateUnregistered || state == NYPLBookStateHolding) {
      // Check out the book
      [self startBorrowForBook:book attemptDownload:YES borrowCompletion:nil];
#if FEATURE_OVERDRIVE_AUTH
    } else if ([book.distributor isEqualToString:OverdriveAPI.distributorKey] && book.defaultBookContentType == NYPLBookContentTypeAudiobook) {
      NSURL *URL = book.defaultAcquisition.hrefURL;
        
      [[OverdriveAPIExecutor shared] fulfillBookWithUrlString:URL.absoluteString
                                                     username:[[NYPLUserAccount sharedAccount] barcode]
                                                          PIN:[[NYPLUserAccount sharedAccount] PIN]
                                                   completion:^(NSDictionary<NSString *,id> * _Nullable responseHeaders, NSError * _Nullable error) {
        if (error) {
          [NYPLErrorLogger logError:error
                            summary:@"Overdrive audiobook fulfillment error"
                           metadata:@{
                             @"responseHeaders": responseHeaders ?: @"N/A",
                             @"acquisitionURL": URL ?: @"N/A",
                             @"book": book.loggableDictionary,
                             @"bookRegistryState": [NYPLBookStateHelper stringValueFromBookState:state]
                           }];
          [self failDownloadWithAlertForBook:book];
          return;
        }

        NSString *scope = responseHeaders[@"x-overdrive-scope"] ?: responseHeaders[@"X-Overdrive-Scope"];
        NSString *requestURLString = responseHeaders[@"location"] ?: responseHeaders[@"Location"];
        
        if (!scope || !requestURLString) {
          [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeOverdriveFulfillResponseParseFail
                                    summary:@"Overdrive audiobook fulfillment: wrong headers"
                                   metadata:@{
                                     @"responseHeaders": responseHeaders ?: @"N/A",
                                     @"acquisitionURL": URL ?: @"N/A",
                                     @"book": book.loggableDictionary,
                                     @"bookRegistryState": [NYPLBookStateHelper stringValueFromBookState:state]
                                   }];
          [self failDownloadWithAlertForBook:book];
          return;
        }
          
        if ([[OverdriveAPIExecutor shared] hasValidPatronTokenWithUsername:[[NYPLUserAccount sharedAccount] barcode] scope:scope]) {
          // Use existing Patron Token
          NSURLRequest *request = [[OverdriveAPIExecutor shared] getManifestRequestWithUrlString:requestURLString
                                                                                        username:[[NYPLUserAccount sharedAccount] barcode]
                                                                                           scope:scope];
          [self addDownloadTaskWithRequest:request book:book];
        } else {
          [[OverdriveAPIExecutor shared]
           refreshPatronTokenWithKey:NYPLSecrets.overdriveClientKey
           secret:NYPLSecrets.overdriveClientSecret
           username:[[NYPLUserAccount sharedAccount] barcode]
           PIN:[[NYPLUserAccount sharedAccount] PIN]
           scope:scope
           completion:^(NSError * _Nullable error) {
            if (error) {
              [NYPLErrorLogger logError:error
                                summary:@"Overdrive audiobook fulfillment: error refreshing patron token"
                               metadata:@{
                                 @"responseHeaders": responseHeaders ?: @"N/A",
                                 @"acquisitionURL": URL ?: @"N/A",
                                 @"book": book.loggableDictionary,
                                 @"bookRegistryState": [NYPLBookStateHelper stringValueFromBookState:state]
                               }];
              [self failDownloadWithAlertForBook:book];
              return;
            }
              
            NSURLRequest *req = [[OverdriveAPIExecutor shared]
                                 getManifestRequestWithUrlString:requestURLString
                                 username:[[NYPLUserAccount sharedAccount] barcode]
                                 scope:scope];
            [self addDownloadTaskWithRequest:req book:book];
          }];
        }
      }];
#endif//FEATURE_OVERDRIVE_AUTH
    } else {
      // Actually download the book.
      NSURL *URL = book.defaultAcquisition.hrefURL;

      NSURLRequest *request;
      if (initedRequest) {
        request = initedRequest;
      } else {
        request = [[NYPLNetworkExecutor.shared requestFor:URL] mutableCopy];
      }

      if(!request.URL) {
        // Originally this code just let the request fail later on, but apparently resuming an
        // NSURLSessionDownloadTask created from a request with a nil URL pathetically results in a
        // segmentation fault.
        NYPLLOG(@"Aborting request with invalid URL.");
        [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeDownloadFail
                                  summary:@"Book download failure: nil download URL"
                                 metadata:@{
                                   @"acquisitionURL": URL ?: @"N/A",
                                   @"book": book.loggableDictionary,
                                   @"bookRegistryState": [NYPLBookStateHelper stringValueFromBookState:state]
                                 }];
        [self failDownloadWithAlertForBook:book];
        return;
      }

      if (NYPLUserAccount.sharedAccount.cookies && state != NYPLBookStateSAMLStarted) {
        [[NYPLBookRegistry sharedRegistry] setState:NYPLBookStateSAMLStarted forIdentifier:book.identifier];

        NSMutableArray *someCookies = NYPLUserAccount.sharedAccount.cookies.mutableCopy;
        NSMutableURLRequest *mutableRequest = request.mutableCopy;

        dispatch_async(dispatch_get_main_queue(), ^{
          __weak NYPLMyBooksDownloadCenter *weakSelf = self;

          mutableRequest.cachePolicy = NSURLRequestReloadIgnoringCacheData;

          void (^loginCancelHandler)(void) = ^{
            [[NYPLBookRegistry sharedRegistry] setState:NYPLBookStateDownloadNeeded forIdentifier:book.identifier];
            [weakSelf cancelDownloadForBookIdentifier:book.identifier];
          };

          void (^bookFoundHandler)(NSURLRequest * _Nullable, NSArray<NSHTTPCookie *> * _Nonnull) = ^(NSURLRequest * _Nullable request, NSArray<NSHTTPCookie *> * _Nonnull cookies) {
            [NYPLUserAccount.sharedAccount setCookies:cookies];
            [weakSelf startDownloadForBook:book withRequest:request];
          };

          void (^problemFoundHandler)(NYPLProblemDocument * _Nullable) = ^(__unused NYPLProblemDocument * _Nullable problemDocument) {
            [[NYPLBookRegistry sharedRegistry] setState:NYPLBookStateDownloadNeeded forIdentifier:book.identifier];

            __weak __auto_type wSelf = self;
            [self.reauthenticator authenticateIfNeededUsingExistingCredentials:NO
                                                      authenticationCompletion:^{
              [wSelf startDownloadForBook:book];
            }];
          };

          NYPLCookiesWebViewModel *model = [[NYPLCookiesWebViewModel alloc] initWithCookies:someCookies
                                                                                    request:mutableRequest
                                                                     loginCompletionHandler:nil
                                                                         loginCancelHandler:loginCancelHandler
                                                                           bookFoundHandler:bookFoundHandler
                                                                        problemFoundHandler:problemFoundHandler
                                                                        autoPresentIfNeeded:YES]; // <- this will cause a web view to retain a cycle

          NYPLCookiesWebViewController *cookiesVC = [[NYPLCookiesWebViewController alloc] initWithModel:model];
          [cookiesVC loadViewIfNeeded];
        });
      } else {
        // clear all cookies
        // NB: I think for anything other than SAML this will result in a no-op
        NSHTTPCookieStorage *cookieStorage = self.session.configuration.HTTPCookieStorage;
        for (NSHTTPCookie *each in cookieStorage.cookies) {
          [cookieStorage deleteCookie:each];
        }

        // set new cookies
        // NB: I think for anything other than SAML this will result in a no-op
        for (NSHTTPCookie *cookie in NYPLUserAccount.sharedAccount.cookies) {
          [self.session.configuration.HTTPCookieStorage setCookie:cookie];
        }

        [self addDownloadTaskWithRequest:request book:book];
      }
    }
  } else {
    [NYPLAccountSignInViewController
     requestCredentialsWithCompletion:^{
       [[NYPLMyBooksDownloadCenter sharedDownloadCenter] startDownloadForBook:book];
     }];
  }
}

- (void)addDownloadTaskWithRequest:(NSURLRequest *)request
                              book:(NYPLBook *)book
{
  if (book == nil || request == nil) {
    NYPLLOG_F(@"Unable to add download task for book [%@] with request: %@",
              book.loggableDictionary, request.loggableString)
    [self alertForProblemDocument:nil error:nil book:book];
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

  // if the book ID is nil something seriously wrong is happening that should
  // be looked at *right now*
  assert(book.identifier != nil);

  // It is important to issue this immediately because a previous download may have left the
  // progress for the book at greater than 0.0 and we do not want that to be temporarily shown to
  // the user. As such, calling |broadcastUpdate| is not appropriate due to the delay.
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NSNotification.NYPLMyBooksDownloadCenterDidChange
   object:self
   userInfo:@{
     NYPLNotificationKeys.bookIDKey: book.identifier ?: @""
   }];
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
    
#if defined(AXIS)
    NYPLAxisBookDownloadAdapter *adapter = [self.bookIdentifierToAxisAdapter
                                    objectForKey:identifier];
    [adapter downloadCancelledByUser];
    [self.bookIdentifierToAxisAdapter removeObjectForKey:identifier];
#endif
    
    [info.downloadTask
     cancelByProducingResumeData:^(__attribute__((unused)) NSData *resumeData) {
       [[NYPLBookRegistry sharedRegistry]
        setState:NYPLBookStateDownloadNeeded forIdentifier:identifier];
       
      [self broadcastUpdate:identifier];
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

- (double)downloadProgressForBookIdentifier:(NSString *const)bookIdentifier
{
  return [self downloadInfoForBookIdentifier:bookIdentifier].downloadProgress;
}

#pragma mark - Send out NYPLMyBooksDownloadCenterDidChange

- (void)broadcastUpdate:(NSString *)bookID
{
  // We avoid issuing redundant notifications to prevent overwhelming UI updates.
  if(self.broadcastScheduled) return;
  
  self.broadcastScheduled = YES;
  
  // This needs to be queued on the main run loop. If we queue it elsewhere, it may end up never
  // firing due to a run loop becoming inactive.
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
    self.broadcastScheduled = NO;

    // if the book ID is nil something seriously wrong is happening that should
    // be looked at *right now*
    assert(bookID != nil);

    [[NSNotificationCenter defaultCenter]
     postNotificationName:NSNotification.NYPLMyBooksDownloadCenterDidChange
     object:self
     userInfo:@{
       NYPLNotificationKeys.bookIDKey: bookID ?: @""
     }];
  });
}

#pragma mark - Return Logic

- (void)returnBookWithIdentifier:(NSString *)identifier
{
  NYPLBook *book = [[NYPLBookRegistry sharedRegistry] bookForIdentifier:identifier];
  NYPLBookState state = [[NYPLBookRegistry sharedRegistry] stateForIdentifier:identifier];

  // Process Adobe Return
#if defined(FEATURE_DRM_CONNECTOR)
  NSString *fulfillmentId = [[NYPLBookRegistry sharedRegistry] fulfillmentIdForIdentifier:identifier];

  // ----------------------------------------------

  if (fulfillmentId && NYPLUserAccount.sharedAccount.requiresUserAuthentication) {
    NYPLLOG_F(@"Return attempt for book. userID: %@",[[NYPLUserAccount sharedAccount] userID]);
    [[NYPLADEPT sharedInstance] returnLoan:fulfillmentId
                                    userID:[[NYPLUserAccount sharedAccount] userID]
                                  deviceID:[[NYPLUserAccount sharedAccount] deviceID]
                                completion:^(BOOL success, NSError *error) {
      if(success) {
        [self revokeLoanAndRemoveBook:book state:state];
      } else {
        NYPLLOG(@"Failed to return loan via NYPLAdept.");
        [self presentAlertForError:error
                       orErrorDict:nil
                     returningBook:book];
      }
    }];
  } else {
    // if we have no fulfillment ID or we don't require authentication, we just
    // need to let the Circulation Manager server know and remove the book
    [self revokeLoanAndRemoveBook:book state:state];
  }
#else
  [self revokeLoanAndRemoveBook:book state:state];
#endif//FEATURE_DRM_CONNECTOR
}

- (void)revokeLoanAndRemoveBook:(NYPLBook *)book state:(NYPLBookState)state
{
  BOOL didDownloadBook = (state == NYPLBookStateDownloadSuccessful
                          || state == NYPLBookStateUsed);
  NSString *const identifier = book.identifier;

  // The main case for not having a revoke link is when the library doesn't
  // authenticate its users. In the case there's no server-side loan to revoke.
  if (!book.revokeURL) {
    if (didDownloadBook) {
      [self deleteLocalContentForBookIdentifier:identifier];
    }
    [[NYPLBookRegistry sharedRegistry] removeBookForIdentifier:identifier];
    [[NYPLBookRegistry sharedRegistry] save];
    return;
  }

  [[NYPLBookRegistry sharedRegistry] setProcessing:YES forIdentifier:book.identifier];

  // revoke loan with the CM
  [NYPLOPDSFeedFetcher fetchOPDSFeedWithUrl:book.revokeURL
                            networkExecutor:[NYPLNetworkExecutor shared]
                           shouldResetCache:NO
                                 completion:^(NYPLOPDSFeed * _Nullable feed, NSDictionary<NSString *,id> * _Nullable errorDict) {
    [[NYPLBookRegistry sharedRegistry] setProcessing:NO forIdentifier:book.identifier];

    if (feed && feed.entries.count == 1)  {
      NYPLOPDSEntry *const entry = feed.entries[0];
      if(didDownloadBook) {
        [self deleteLocalContentForBookIdentifier:identifier];
      }
      NYPLBook *returnedBook = [NYPLBook bookWithEntry:entry];
      [[NYPLBookRegistry sharedRegistry] updateAndRemoveBook:returnedBook];
      [[NYPLBookRegistry sharedRegistry] save];
      [NYPLMyBooksNotifier announceSuccessfulBookReturn:returnedBook];
      return;
    }

    // handle errors
    if ([errorDict[@"type"] isEqualToString:NYPLProblemDocument.TypeNoActiveLoan]) {
      if (didDownloadBook) {
        [self deleteLocalContentForBookIdentifier:identifier];
      }
      [[NYPLBookRegistry sharedRegistry] removeBookForIdentifier:identifier];
      [[NYPLBookRegistry sharedRegistry] save];
      [NYPLMyBooksNotifier announceSuccessfulBookReturn:book];
    } else if ([errorDict[@"type"] isEqualToString:NYPLProblemDocument.TypeInvalidCredentials]) {
      NYPLLOG(@"Invalid credentials problem when returning a book, present sign in VC");
      __weak __auto_type wSelf = self;
      [self.reauthenticator authenticateIfNeededUsingExistingCredentials:NO
                                                authenticationCompletion:^{
        [wSelf returnBookWithIdentifier:identifier];
      }];
    } else {
      [self presentAlertForError:nil orErrorDict:errorDict returningBook:book];
    }
  }];
}

#pragma mark - Error Handling

/// Notifies the book registry AND the user that a book failed to download.
/// @note This method does NOT log to Crashlytics.
/// @param book The book that failed to download.
- (void)failDownloadWithAlertForBook:(NYPLBook *const)book
{
  [[NYPLBookRegistry sharedRegistry]
   addBook:book
   location:nil
   state:NYPLBookStateDownloadFailed
   fulfillmentId:nil
   readiumBookmarks:nil
   genericBookmarks:nil];

#if defined(AXIS)
  [self.bookIdentifierToAxisAdapter removeObjectForKey:book.identifier];
#endif

  dispatch_async(dispatch_get_main_queue(), ^{
    NSString *formattedMessage = [NSString stringWithFormat:NSLocalizedString(@"DownloadCouldNotBeCompletedFormat", nil), book.title];
    UIAlertController *alert = [NYPLAlertUtils alertWithTitle:@"DownloadFailed" message:formattedMessage];
    [NYPLAlertUtils presentFromViewControllerOrNilWithAlertController:alert viewController:nil animated:YES completion:nil];
  });

  [self broadcastUpdate:book.identifier];
}

// this doesn't log to crashlytics because it assumes that the caller
// is responsible for that.
- (void)alertForProblemDocument:(NYPLProblemDocument *)problemDoc
                          error:(NSError *)error
                           book:(NYPLBook *)book
{
  NSString *msg = [NSString stringWithFormat:
                   NSLocalizedString(@"DownloadCouldNotBeCompletedFormat", nil),
                   book.title];
  UIAlertController *alert = [NYPLAlertUtils alertWithTitle:@"DownloadFailed"
                                                    message:msg];
  if (problemDoc) {
    [[NYPLProblemDocumentCacheManager sharedInstance]
     cacheProblemDocument:problemDoc
     key:book.identifier];
    [NYPLAlertUtils setProblemDocumentWithController:alert
                                            document:problemDoc
                                              append:YES];
    if ([problemDoc.type isEqualToString:NYPLProblemDocument.TypeNoActiveLoan]) {
      [[NYPLBookRegistry sharedRegistry] removeBookForIdentifier:book.identifier];
    }
  } else if (error && !error.localizedDescriptionWithRecovery.isEmptyNoWhitespace) {
    alert.message = [NSString stringWithFormat:@"%@\n\nError: %@",
                     msg, error.localizedDescriptionWithRecovery];
  }

  [NYPLAlertUtils presentFromViewControllerOrNilWithAlertController:alert viewController:nil animated:YES completion:nil];
}

- (void)presentAlertForError:(NSError *)error
                 orErrorDict:(NSDictionary *)errorDict
               returningBook:(NYPLBook *)book
{
  [NYPLErrorLogger logError:error
                    summary:@"Failed returning book"
                   metadata:@{
    @"errorDict": errorDict ?: @"",
    @"returningBook": book.loggableDictionary ?: @""
  }];

  NSString *msg = NSLocalizedString(@"ReturnCouldNotBeCompletedFormat", nil);
  msg = [NSString stringWithFormat:msg, book.title];
  if (error) {
    msg = [NSString stringWithFormat:@"%@\n%@",
           msg, error.localizedDescriptionWithRecovery];
  }

  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    UIAlertController *alert = [NYPLAlertUtils
                                alertWithTitle:@"ReturnFailed"
                                message:msg];
    if (errorDict) {
      NYPLProblemDocument *problemDoc = [NYPLProblemDocument fromDictionary:errorDict];
      [NYPLAlertUtils setProblemDocumentWithController:alert
                                              document:problemDoc
                                                append:YES];
    }
    [NYPLAlertUtils presentFromViewControllerOrNilWithAlertController:alert
                                                       viewController:nil
                                                             animated:YES
                                                           completion:nil];
  }];
}

- (void)logBookDownloadFailure:(NYPLBook *)book
                        reason:(NSString *)reason
                  downloadTask:(NSURLSessionTask *)downloadTask
                      metadata:(NSDictionary<NSString*, id> *)metadata
{
  NSString *rights = [[self downloadInfoForBookIdentifier:book.identifier]
                      rightsManagementString];
  NSString *bookType = [NYPLBookContentTypeConverter stringValueOf:
                        [book defaultBookContentType]];
  NSString *context = [NSString stringWithFormat:@"%@ %@ download fail: %@",
                       book.distributor, bookType, reason];

  NSMutableDictionary<NSString*, id> *dict = [[NSMutableDictionary alloc] initWithDictionary:metadata];
  dict[@"book"] = book.loggableDictionary;
  dict[@"rightsManagement"] = rights;
  dict[@"taskOriginalRequest"] = downloadTask.originalRequest.loggableString;
  dict[@"taskCurrentRequest"] = downloadTask.currentRequest.loggableString;
  dict[@"response"] = downloadTask.response ?: @"N/A";
  dict[@"downloadError"] = downloadTask.error ?: @"N/A";

  [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeDownloadFail
                            summary:context
                           metadata:dict];
}

#if defined(FEATURE_DRM_CONNECTOR)
  
#pragma mark - NYPLADEPTDelegate
  
- (void)adept:(__attribute__((unused)) NYPLADEPT *)adept didUpdateProgress:(double)progress tag:(NSString *)tag
{
  self.bookIdentifierToDownloadInfo[tag] =
  [[self downloadInfoForBookIdentifier:tag] withDownloadProgress:progress];

  [self broadcastUpdate:tag];
}

- (void)    adept:(__attribute__((unused)) NYPLADEPT *)adept
didFinishDownload:(BOOL)didFinishDownload
            toURL:(NSURL *)adeptToURL
    fulfillmentID:(NSString *)fulfillmentID
     isReturnable:(BOOL)isReturnable
       rightsData:(NSData *)rightsData
              tag:(NSString *)tag
            error:(NSError *)adeptError
{
  NYPLBook *const book = [[NYPLBookRegistry sharedRegistry] bookForIdentifier:tag];
  NSString *rights = [[NSString alloc] initWithData:rightsData encoding:kCFStringEncodingUTF8];
  BOOL didSucceedCopying = NO;
  NSURL *destURL = [self fileURLForBookIndentifier:book.identifier];

  if(didFinishDownload) {
    [[NSFileManager defaultManager] removeItemAtURL:destURL error:NULL];
    if (destURL == nil) {
      [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeAdobeDRMFulfillmentFail
                                summary:@"Adobe DRM error: destination file URL unavailable"
                               metadata:@{
                                 @"adeptError": adeptError ?: @"N/A",
                                 @"fileURLToRemove": adeptToURL ?: @"N/A",
                                 @"book": book.loggableDictionary ?: @"N/A",
                                 @"AdobeFulfilmmentID": fulfillmentID ?: @"N/A",
                                 @"AdobeRights": rights ?: @"N/A",
                                 @"AdobeTag": tag ?: @"N/A"
                               }];
      [self failDownloadWithAlertForBook:book];
      return;
    }
    
    // This needs to be a copy else the Adept connector will explode when it tries to delete the
    // temporary file. This is saving the actual book to disk in its final location.
    NSError *copyError = nil;
    didSucceedCopying = [[NSFileManager defaultManager] copyItemAtURL:adeptToURL
                                                                toURL:destURL
                                                                error:&copyError];
    if(!didSucceedCopying) {
      [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeAdobeDRMFulfillmentFail
                                summary:@"Adobe DRM error: failure copying file"
                               metadata:@{
                                 @"adeptError": adeptError ?: @"N/A",
                                 @"copyError": copyError ?: @"N/A",
                                 @"fromURL": adeptToURL ?: @"N/A",
                                 @"destURL": destURL ?: @"N/A",
                                 @"book": book.loggableDictionary ?: @"N/A",
                                 @"AdobeFulfilmmentID": fulfillmentID ?: @"N/A",
                                 @"AdobeRights": rights ?: @"N/A",
                                 @"AdobeTag": tag ?: @"N/A"
                               }];
    }
  } else {
    [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeAdobeDRMFulfillmentFail
                              summary:@"Adobe DRM error: did not finish download"
                             metadata:@{
                               @"adeptError": adeptError ?: @"N/A",
                               @"adeptToURL": adeptToURL ?: @"N/A",
                               @"book": book.loggableDictionary ?: @"N/A",
                               @"AdobeFulfilmmentID": fulfillmentID ?: @"N/A",
                               @"AdobeRights": rights ?: @"N/A",
                               @"AdobeTag": tag ?: @"N/A"
                             }];
  }

  if(didFinishDownload == NO || didSucceedCopying == NO) {
    [self failDownloadWithAlertForBook:book];
    return;
  }

  //
  // The rights data are stored in {book_filename}_rights.xml,
  // alongside with the book because Readium+DRM expect this when
  // opening the EPUB 3.
  // See Container::Open(const string& path) in container.cpp.
  //
  if(![rightsData writeToFile:[[destURL path]
                               stringByAppendingString:ADOBE_RIGHTS_XML_SUFFIX]
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

  [self broadcastUpdate:book.identifier];
}
  
- (void)adept:(__attribute__((unused)) NYPLADEPT *)adept didCancelDownloadWithTag:(NSString *)tag
{
  [[NYPLBookRegistry sharedRegistry]
   setState:NYPLBookStateDownloadNeeded forIdentifier:tag];

  [self broadcastUpdate:tag];
}

- (void)didIgnoreFulfillmentWithNoAuthorizationPresent
{
  // NOTE: This is cut and pasted from a previous implementation:
  // "This handles a bug that seems to occur when the user updates,
  // where the barcode and pin are entered but according to ADEPT the device
  // is not authorized. To be used, the account must have a barcode and pin."
  [self.reauthenticator authenticateIfNeededUsingExistingCredentials:YES
                                            authenticationCompletion:nil];
}

#endif


#pragma mark - LCP

/// Fulfill LCP license
/// @param fileUrl Downloaded LCP license URL
/// @param book `NYPLBook` Book
/// @param downloadTask download task
- (void)fulfillLCPLicense:(NSURL *)fileUrl
                  forBook:(NYPLBook *)book
             downloadTask:(NSURLSessionDownloadTask *)downloadTask
{
  #if defined(LCP)
  LCPLibraryService *lcpService = [[LCPLibraryService alloc] init];
  // Ensure correct license extension
  NSURL *licenseUrl = [[fileUrl URLByDeletingPathExtension] URLByAppendingPathExtension:lcpService.licenseExtension];
  NSError *replaceError;
  [[NSFileManager defaultManager] replaceItemAtURL:licenseUrl
                                     withItemAtURL:fileUrl
                                    backupItemName:nil
                                           options:NSFileManagerItemReplacementUsingNewMetadataOnly
                                  resultingItemURL:nil
                                             error:&replaceError];
  if (replaceError) {
    [NYPLErrorLogger logError:replaceError summary:@"Error renaming LCP license file" metadata:@{
      @"fileUrl": fileUrl ?: @"nil",
      @"licenseUrl": licenseUrl ?: @"nil",
      @"book": [book loggableDictionary] ?: @"nil"
    }];
    [self failDownloadWithAlertForBook:book];
    return;
  }
  // LCP library expects an .lcpl file at licenseUrl
  // localUrl is URL of downloaded file with embedded license
  [lcpService fulfill:licenseUrl completion:^(NSURL *localUrl, NSError *error) {
    if (error) {
      NSString *summary = [NSString stringWithFormat:@"%@ LCP license fulfillment error",
                           book.distributor];
      [NYPLErrorLogger logError:error
                        summary:summary
                       metadata:@{
                         @"book": book.loggableDictionary ?: @"N/A",
                         @"licenseURL": licenseUrl  ?: @"N/A",
                         @"localURL": localUrl  ?: @"N/A",
                       }];
      [self failDownloadWithAlertForBook:book];
      return;
    }
    BOOL success = [self replaceBook:book
                       withFileAtURL:localUrl
                     forDownloadTask:downloadTask];
    if (!success) {
      [self failDownloadWithAlertForBook:book];
    }
  }];
  #endif
}

#if defined(AXIS)
- (void)downloadProgressDidUpdateTo:(double)progress forBook:(NYPLBook * _Nonnull)book {
  self.bookIdentifierToDownloadInfo[book.identifier] =
  [[self downloadInfoForBookIdentifier:book.identifier]
   withDownloadProgress:progress];

  [self broadcastUpdate:book.identifier];
}
#endif

#if FEATURE_AUDIOBOOKS
- (void)downloadProgressDidUpdateTo:(double)progress forBookIdentifier:(NSString *)bookID {
  NYPLLOG_F(@"Download progress updated to %f for %@", progress, bookID);
  self.bookIdentifierToDownloadInfo[bookID] = [[self downloadInfoForBookIdentifier:bookID]
                                               withDownloadProgress:progress];

  [self broadcastUpdate:bookID];
}
#endif

@end
