@import MediaPlayer;
@import NYPLAudiobookToolkit;
@import PDFRendererProvider;
#if FEATURE_OVERDRIVE
@import OverdriveProcessor;
#endif

#import "NYPLAccountSignInViewController.h"
#import "NYPLBook.h"
#import "NYPLBookDownloadFailedCell.h"
#import "NYPLBookDownloadingCell.h"
#import "NYPLBookLocation.h"
#import "NYPLBookNormalCell.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLRootTabBarController.h"
#import "NSString+NYPLStringAdditions.h"

#import "NSURLRequest+NYPLURLRequestAdditions.h"
#import "NYPLJSON.h"
#import "NYPLReachabilityManager.h"

#import "NYPLBookCellDelegate.h"
#import "SimplyE-Swift.h"

#if defined(FEATURE_DRM_CONNECTOR)
#import <ADEPT/ADEPT.h>
#endif

@interface NYPLBookCellDelegate () <RefreshDelegate>

@property (nonatomic) NYPLBook *book;
@property DefaultAudiobookManager *manager;
@property (strong) NSLock *refreshAudiobookLock;

@end

@implementation NYPLBookCellDelegate

+ (instancetype)sharedDelegate
{
  static dispatch_once_t predicate;
  static NYPLBookCellDelegate *sharedDelegate = nil;
  
  dispatch_once(&predicate, ^{
    sharedDelegate = [[self alloc] init];
    if(!sharedDelegate) {
      NYPLLOG(@"Failed to create shared delegate.");
    }
  });
  
  return sharedDelegate;
}

- (instancetype)init
{
  self = [super init];
    
  _refreshAudiobookLock = [[NSLock alloc] init];
  
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark NYPLBookButtonsDelegate

- (void)didSelectReturnForBook:(NYPLBook *)book
{
  [[NYPLMyBooksDownloadCenter sharedDownloadCenter] returnBookWithIdentifier:book.identifier];
}

- (void)didSelectDownloadForBook:(NYPLBook *)book
{
  [[NYPLMyBooksDownloadCenter sharedDownloadCenter] startDownloadForBook:book];
}

- (void)didSelectReadForBook:(NYPLBook *)book successCompletion:(void(^)(void))successCompletion
{
#if defined(FEATURE_DRM_CONNECTOR)
  // Try to prevent blank books bug

  NYPLUserAccount *user = [NYPLUserAccount sharedAccount];
  if ([user hasCredentials]
      && ![[NYPLADEPT sharedInstance] isUserAuthorized:[user userID]
                                            withDevice:[user deviceID]]) {
    // NOTE: This was cut and pasted while refactoring preexisting work:
    // "This handles a bug that seems to occur when the user updates,
    // where the barcode and pin are entered but according to ADEPT the device
    // is not authorized. To be used, the account must have a barcode and pin."
    NYPLReauthenticator *reauthenticator = [[NYPLReauthenticator alloc] init];
    [reauthenticator authenticateIfNeeded:user
                 usingExistingCredentials:YES
                 authenticationCompletion:^{
      dispatch_async(dispatch_get_main_queue(), ^{
        [self openBook:book successCompletion:successCompletion]; // with successful DRM activation
      });
    }];
  } else {
    [self openBook:book successCompletion:successCompletion];
  }
#else
  [self openBook:book successCompletion:successCompletion];
#endif
}

- (void)openBook:(NYPLBook *)book successCompletion:(void(^)(void))successCompletion
{
  [NYPLCirculationAnalytics postEvent:@"open_book" withBook:book];

  switch (book.defaultBookContentType) {
    case NYPLBookContentTypeEPUB:
      [self openEPUB:book successCompletion:successCompletion];
      break;
    case NYPLBookContentTypePDF:
      [self openPDF:book];
      break;
    case NYPLBookContentTypeAudiobook:
      [self openAudiobook:book];
      break;
    default:
      [self presentUnsupportedItemError];
      break;
  }
}

- (void)openEPUB:(NYPLBook *)book successCompletion:(void(^)(void))successCompletion
{
  NSURL *const url = [[NYPLMyBooksDownloadCenter sharedDownloadCenter]
                      fileURLForBookIndentifier:book.identifier];
  [[NYPLRootTabBarController sharedController] presentBook:book
                                               fromFileURL:url
                                         successCompletion:successCompletion];

  [NYPLAnnotations requestServerSyncStatusForAccount:[NYPLUserAccount sharedAccount] completion:^(BOOL enableSync) {
    if (enableSync == YES) {
      Account *currentAccount = [[AccountsManager sharedInstance] currentAccount];
      currentAccount.details.syncPermissionGranted = enableSync;
    }
  }];
}

- (void)openPDF:(NYPLBook *)book {

  NSURL *const url = [[NYPLMyBooksDownloadCenter sharedDownloadCenter] fileURLForBookIndentifier:book.identifier];

  NSArray<NYPLBookLocation *> *const genericMarks = [[NYPLBookRegistry sharedRegistry] genericBookmarksForIdentifier:book.identifier];
  NSMutableArray<MinitexPDFPage *> *const bookmarks = [NSMutableArray array];
  for (NYPLBookLocation *loc in genericMarks) {
    NSData *const data = [loc.locationString dataUsingEncoding:NSUTF8StringEncoding];
    MinitexPDFPage *const page = [MinitexPDFPage fromData:data];
    [bookmarks addObject:page];
  }

  MinitexPDFPage *startingPage;
  NYPLBookLocation *const startingBookLocation = [[NYPLBookRegistry sharedRegistry] locationForIdentifier:book.identifier];
  NSData *const data = [startingBookLocation.locationString dataUsingEncoding:NSUTF8StringEncoding];
  if (data) {
    startingPage = [MinitexPDFPage fromData:data];
    NYPLLOG_F(@"Returning to PDF Location: %@", startingPage);
  }

  id<MinitexPDFViewController> pdfViewController = [MinitexPDFViewControllerFactory createWithFileUrl:url openToPage:startingPage bookmarks:bookmarks annotations:nil];

  if (pdfViewController) {
    pdfViewController.delegate = [[NYPLPDFViewControllerDelegate alloc] initWithBookIdentifier:book.identifier];
    [(UIViewController *)pdfViewController setHidesBottomBarWhenPushed:YES];
    [[NYPLRootTabBarController sharedController] pushViewController:(UIViewController *)pdfViewController animated:YES];
  } else {
    [self presentUnsupportedItemError];
    return;
  }
}

- (void)openAudiobook:(NYPLBook *)book {
  NSURL *const url = [[NYPLMyBooksDownloadCenter sharedDownloadCenter] fileURLForBookIndentifier:book.identifier];
  NSData *const data = [NSData dataWithContentsOfURL:url];
  if (data == nil) {
    [self presentCorruptedItemErrorWithLog:@{
      @"book": book.loggableDictionary ?: @"N/A",
      @"fileURL": url ?: @"N/A"
    }];
    return;
  }

  id const json = NYPLJSONObjectFromData(data);
    
  NSMutableDictionary *dict = nil;
    
#if FEATURE_OVERDRIVE
  if ([book.distributor isEqualToString:OverdriveDistributorKey]) {
    dict = [(NSMutableDictionary *)json mutableCopy];
    dict[@"id"] = book.identifier;
  }
#endif
  
#if defined(LCP)
  if ([LCPAudiobooks canOpenBook:book]) {
    LCPAudiobooks *lcpAudiobooks = [[LCPAudiobooks alloc] initFor:url];
    [lcpAudiobooks contentDictionaryWithCompletion:^(NSDictionary * _Nullable dict, NSError * _Nullable error) {
      if (error) {
        [self presentUnsupportedItemError];
        return;
      }
      if (dict) {
        NSMutableDictionary *mutableDict = [dict mutableCopy];
        mutableDict[@"id"] = book.identifier;
        [self openAudiobook:book withJSON:mutableDict decryptor:lcpAudiobooks];
      }
    }];
  } else {
    // Not an LCP book
    [self openAudiobook:book withJSON:dict ?: json decryptor:nil];
  }
#else
  [self openAudiobook:book withJSON:dict ?: json decryptor:nil];
#endif
}

- (void)openAudiobook:(NYPLBook *)book withJSON:(NSDictionary *)json decryptor:(id<DRMDecryptor>)audiobookDrmDecryptor {
  [AudioBookVendorsHelper updateVendorKeyWithBook:json completion:^(NSError * _Nullable error) {
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
      id<Audiobook> const audiobook = [AudiobookFactory audiobook:json decryptor:audiobookDrmDecryptor];
      
      if (!audiobook) {
        if (error) {
          [self presentDRMKeyError:error];
        } else {
          [self presentUnsupportedItemError];
        }
        return;
      }

      AudiobookMetadata *const metadata = [[AudiobookMetadata alloc]
                                           initWithTitle:book.title
                                           authors:@[book.authors]];
      DefaultAudiobookManager *const manager = [[DefaultAudiobookManager alloc]
                                                initWithMetadata:metadata
                                                audiobook:audiobook];

      AudiobookPlayerViewController *audiobookVC = [self createPlayerVCForAudiobook:audiobook
                                                                           withBook:book
                                                        configuringAudiobookManager:manager];

      // present audiobook player on screen
      [[NYPLRootTabBarController sharedController] pushViewController:audiobookVC animated:YES];

      NYPLBookLocation *const bookLocation =
      [[NYPLBookRegistry sharedRegistry] locationForIdentifier:book.identifier];

      // move player to saved position
      if (bookLocation) {
        NSData *const data = [bookLocation.locationString dataUsingEncoding:NSUTF8StringEncoding];
        ChapterLocation *const chapterLocation = [ChapterLocation fromData:data];
        NYPLLOG_F(@"Returning to Audiobook Location: %@", chapterLocation);
        [manager.audiobook.player movePlayheadToLocation:chapterLocation];
      }

      // poll audiobook player so that we can save the reading position
      [self scheduleTimerForAudiobook:book manager:manager viewController:audiobookVC];
    }];
  }];
}

- (AudiobookPlayerViewController *)createPlayerVCForAudiobook:(id<Audiobook>)audiobook
                                                     withBook:(NYPLBook *)book
                                  configuringAudiobookManager:(id<AudiobookManager>)manager
{
  manager.refreshDelegate = self;

  AudiobookPlayerViewController *const audiobookVC = [[AudiobookPlayerViewController alloc]
                                                      initWithAudiobookManager:manager];

  [self registerCallbackForLogHandler];

  [[NYPLBookRegistry sharedRegistry] coverImageForBook:book handler:^(UIImage *image) {
    if (image) {
      [audiobookVC.coverView setImage:image];
    }
  }];

  audiobookVC.hidesBottomBarWhenPushed = YES;
  audiobookVC.view.tintColor = [NYPLConfiguration mainColor];

  __weak AudiobookPlayerViewController *weakAudiobookVC = audiobookVC;
  [manager setPlaybackCompletionHandler:^{
    NSSet<NSString *> *types = [[NSSet alloc] initWithObjects:ContentTypeFindaway, ContentTypeOpenAccessAudiobook, ContentTypeFeedbooksAudiobook, nil];
    NSArray<NYPLOPDSAcquisitionPath *> *paths = [NYPLOPDSAcquisitionPath
                                                 supportedAcquisitionPathsForAllowedTypes:types
                                                 allowedRelations:(NYPLOPDSAcquisitionRelationSetBorrow |
                                                                   NYPLOPDSAcquisitionRelationSetGeneric)
                                                 acquisitions:book.acquisitions];
    if (paths.count > 0) {
      UIAlertController *alert = [NYPLReturnPromptHelper audiobookPromptWithCompletion:^(BOOL returnWasChosen) {
        if (returnWasChosen) {
          [weakAudiobookVC.navigationController popViewControllerAnimated:YES];
          [self didSelectReturnForBook:book];
        }
        [NYPLAppStoreReviewPrompt presentIfAvailable];
      }];
      [[NYPLRootTabBarController sharedController] presentViewController:alert animated:YES completion:nil];
    } else {
      NYPLLOG(@"Skipped Return Prompt with no valid acquisition path.");
      [NYPLAppStoreReviewPrompt presentIfAvailable];
    }
  }];

  return audiobookVC;
}

#pragma mark - Audiobook Methods

- (void)registerCallbackForLogHandler
{
  [DefaultAudiobookManager setLogHandler:^(enum LogLevel level, NSString * _Nonnull message, NSError * _Nullable error) {
    NSString *msg = [NSString stringWithFormat:@"Level: %ld. Message: %@",
                     (long)level, message];

    if (error) {
      [NYPLErrorLogger logError:error
                        summary:@"Error registering audiobook callback for logging"
                       metadata:@{ @"context": msg ?: @"N/A" }];
    } else if (level > LogLevelDebug) {
      NSString *logLevel = (level == LogLevelInfo ?
                            @"info" :
                            (level == LogLevelWarn ? @"warning" : @"error"));
      NSString *summary = [NSString stringWithFormat:@"NYPLAudiobookToolkit::AudiobookManager %@", logLevel];
      [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeAudiobookExternalError
                                summary:summary
                               metadata:@{ @"context": msg ?: @"N/A" }];
    }
  }];
}

// Non-thread safe: currently this is always called on the main thread.
// Even more stricly, since NTPLBookCellDelegate is a singleton (!?), this
// method should be called only when the previous audiobookViewController is
// no longer used.
- (void)scheduleTimerForAudiobook:(NYPLBook *)book
                          manager:(DefaultAudiobookManager *)manager
                   viewController:(AudiobookPlayerViewController *)audiobookVC
{
  self.book = book;
  self.manager = manager;

  __weak UIViewController *const weakAudiobookVC = audiobookVC;
  [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *_Nonnull timer) {
    if (weakAudiobookVC == nil) {
      [timer invalidate];
      NYPLLOG(@"Invalidating audiobook polling timer and resetting BookCellDelegate state");
      self.book = nil;
      self.manager = nil;
      return;
    }

    NSString *const string = [[NSString alloc]
                              initWithData:manager.audiobook.player.currentChapterLocation.toData
                              encoding:NSUTF8StringEncoding];
    [[NYPLBookRegistry sharedRegistry]
     setLocation:[[NYPLBookLocation alloc] initWithLocationString:string renderer:@"NYPLAudiobookToolkit"]
     forIdentifier:book.identifier];
  }];
}

- (void)presentDRMKeyError:(NSError *) error
{
  NSString *title = NSLocalizedString(@"DRM Error", nil);
  NSString *message = error.localizedDescription;
  UIAlertController *alert = [NYPLAlertUtils alertWithTitle:title message:message];
  [NYPLAlertUtils presentFromViewControllerOrNilWithAlertController:alert viewController:nil animated:YES completion:nil];
}

- (void)presentUnsupportedItemError
{
  NSString *title = NSLocalizedString(@"Unsupported Item", nil);
  NSString *message = NSLocalizedString(@"The item you are trying to open is not currently supported.", nil);
  UIAlertController *alert = [NYPLAlertUtils alertWithTitle:title message:message];
  [NYPLAlertUtils presentFromViewControllerOrNilWithAlertController:alert viewController:nil animated:YES completion:nil];
}

- (void)presentCorruptedItemErrorWithLog:(NSDictionary *)loggingMetadata
{
  NSString *title = NSLocalizedString(@"Corrupted Audiobook", nil);
  NSString *message = NSLocalizedString(@"The audiobook you are trying to open appears to be corrupted. Try downloading it again.", nil);
  UIAlertController *alert = [NYPLAlertUtils alertWithTitle:title message:message];
  [NYPLAlertUtils presentFromViewControllerOrNilWithAlertController:alert viewController:nil animated:YES completion:nil];

  [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeAudiobookCorrupted
                            summary:@"Audiobooks: corrupted audiobook"
                           metadata:loggingMetadata];
}

#pragma mark NYPLBookDownloadFailedDelegate

- (void)didSelectCancelForBookDownloadFailedCell:(NYPLBookDownloadFailedCell *const)cell
{
  [[NYPLMyBooksDownloadCenter sharedDownloadCenter]
   cancelDownloadForBookIdentifier:cell.book.identifier];
}

- (void)didSelectTryAgainForBookDownloadFailedCell:(NYPLBookDownloadFailedCell *const)cell
{
  [[NYPLMyBooksDownloadCenter sharedDownloadCenter] startDownloadForBook:cell.book];
}

#pragma mark NYPLBookDownloadingCellDelegate

- (void)didSelectCancelForBookDownloadingCell:(NYPLBookDownloadingCell *const)cell
{
  [[NYPLMyBooksDownloadCenter sharedDownloadCenter]
   cancelDownloadForBookIdentifier:cell.book.identifier];
}

#pragma mark Audiobook Manager Refresh Delegate

- (void)audiobookManagerDidRequestRefresh
{
#if FEATURE_OVERDRIVE
  // while `audiobookManagerDidRequestRefresh` is guaranteed to be called
  // always on the main thread, this lock prevents us from starting the book
  // download a second time before reaching a completion for the first.
  if (![self.refreshAudiobookLock tryLock]) {
    return;
  }

  if ([self.book.distributor isEqualToString:OverdriveDistributorKey]) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateODAudiobookManifest:)
                                                 name:NSNotification.NYPLMyBooksDownloadCenterDidChange
                                               object:nil];
  } else {
    [self.refreshAudiobookLock unlock];
  }
#endif

  [[NYPLBookRegistry sharedRegistry] setState:NYPLBookStateDownloadNeeded forIdentifier:self.book.identifier];
  [[NYPLMyBooksDownloadCenter sharedDownloadCenter] startDownloadForBook:self.book];
}

#if FEATURE_OVERDRIVE
- (void)updateODAudiobookManifest:(NSNotification *)notif
{
  NSString *bookID = notif.userInfo[NYPLNotificationKeys.bookProcessingBookIDKey];

  // if MyBooks changed for any reason but a book update (in which case we
  // would have a nonnull book ID), then it must mean it's either a reset or
  // anyways something that does not concern us because not related to a
  // specific book.
  // Note that if for whatever reason AudioBookVC is deallocated before this
  // callback is called, `self.book` will be nil or potentially *different*.
  if (bookID == nil || bookID.isEmptyNoWhitespace) {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.refreshAudiobookLock unlock];
    return;
  }

  NYPLBookState bookState = [[NYPLBookRegistry sharedRegistry]
                             stateForIdentifier:bookID];
  if (bookState == NYPLBookStateDownloadFailed) {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.refreshAudiobookLock unlock];
    return;
  }

  if (bookState == NYPLBookStateDownloadSuccessful || bookState == NYPLBookStateUsed) {
    // sanity check before casting. Note that self.manager could be nil.
    if (![(NSObject*)self.manager.audiobook isKindOfClass:[OverdriveAudiobook class]]) {
      [[NSNotificationCenter defaultCenter] removeObserver:self];
      [self.refreshAudiobookLock unlock];
      return;
    }

    // odAudiobook definitely nonnull
    OverdriveAudiobook *odAudiobook = (OverdriveAudiobook * __nonnull)self.manager.audiobook;

    NSURL *const bookURL = [[NYPLMyBooksDownloadCenter sharedDownloadCenter]
                            fileURLForBookIndentifier:bookID];
    NSData *const bookData = [NSData dataWithContentsOfURL:bookURL];
    if (bookData == nil) {
      [[NSNotificationCenter defaultCenter] removeObserver:self];
      [self.refreshAudiobookLock unlock];
      [self presentCorruptedItemErrorWithLog:@{
        @"book/bookID": self.book.loggableDictionary ?: bookID,
        @"fileURL": bookURL ?: @"N/A"
      }];
      return;
    }

    // update Overdrive audiobook object with id
    id const json = NYPLJSONObjectFromData(bookData);
    NSMutableDictionary *dict = [(NSMutableDictionary *)json mutableCopy];
    dict[@"id"] = bookID;
    [odAudiobook updateManifestWithJSON:dict];

    [self.manager updateAudiobookWith:odAudiobook.spine];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.refreshAudiobookLock unlock];
  }
}
#endif

@end
