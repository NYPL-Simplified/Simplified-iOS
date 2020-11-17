@import MediaPlayer;
@import NYPLAudiobookToolkit;
@import PDFRendererProvider;
@import OverdriveProcessor;

#import "NYPLAccountSignInViewController.h"
#import "NYPLBook.h"
#import "NYPLBookDownloadFailedCell.h"
#import "NYPLBookDownloadingCell.h"
#import "NYPLBookLocation.h"
#import "NYPLBookNormalCell.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLReaderViewController.h"
#import "NYPLRootTabBarController.h"

#import "NSURLRequest+NYPLURLRequestAdditions.h"
#import "NYPLJSON.h"
#import "NYPLReachabilityManager.h"

#import "NYPLBookCellDelegate.h"
#import "SimplyE-Swift.h"

#if defined(FEATURE_DRM_CONNECTOR)
#import <ADEPT/ADEPT.h>
#endif

@interface NYPLBookCellDelegate () <RefreshDelegate>

@property (nonatomic) NSTimer *timer;
@property (nonatomic) NYPLBook *book;
@property (nonatomic) id<AudiobookManager> manager;
@property (nonatomic, weak) AudiobookPlayerViewController *audiobookViewController;
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

- (void)didSelectReadForBook:(NYPLBook *)book
{ 
  #if defined(FEATURE_DRM_CONNECTOR)
    // Try to prevent blank books bug
    if ((![[NYPLADEPT sharedInstance] isUserAuthorized:[[NYPLUserAccount sharedAccount] userID]
                                           withDevice:[[NYPLUserAccount sharedAccount] deviceID]]) &&
        ([[NYPLUserAccount sharedAccount] hasCredentials])) {
      [NYPLAccountSignInViewController authorizeUsingExistingBarcodeAndPinWithCompletionHandler:^{
        [self openBook:book];   // with successful DRM activation
      }];
    } else {
      [self openBook:book];
    }
  #else
    [self openBook:book];
  #endif
}

- (void)openBook:(NYPLBook *)book
{
  [NYPLCirculationAnalytics postEvent:@"open_book" withBook:book];

  switch (book.defaultBookContentType) {
    case NYPLBookContentTypeEPUB:
      [self openEPUB:book];
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

- (void)openEPUB:(NYPLBook *)book
{
  if (NYPLSettings.shared.useR2) {
    // R2
    [[NYPLRootTabBarController sharedController] presentBook:book];

    [NYPLAnnotations requestServerSyncStatusForAccount:[NYPLUserAccount sharedAccount] completion:^(BOOL enableSync) {
      if (enableSync == YES) {
        Account *currentAccount = [[AccountsManager sharedInstance] currentAccount];
        currentAccount.details.syncPermissionGranted = enableSync;
      }
    }];
  } else {
    // R1
    NYPLReaderViewController *readerVC = [[NYPLReaderViewController alloc] initWithBookIdentifier:book.identifier];
    [[NYPLRootTabBarController sharedController] pushViewController:readerVC animated:YES];
  }
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
    [self presentCorruptedItemErrorForBook:book fromURL:url];
    return;
  }

  id const json = NYPLJSONObjectFromData(data);
    
  NSMutableDictionary *dict = nil;
    
  if ([book.distributor isEqualToString:OverdriveDistributorKey]) {
    dict = [(NSMutableDictionary *)json mutableCopy];
    dict[@"id"] = book.identifier;
  }
  
  [AudioBookVendorsHelper updateVendorKeyWithBook:json completion:^(NSError * _Nullable error) {
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
      id<Audiobook> const audiobook = [AudiobookFactory audiobook: dict ?: json];

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
      id<AudiobookManager> const manager = [[DefaultAudiobookManager alloc]
                                            initWithMetadata:metadata
                                            audiobook:audiobook];
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
      [[NYPLRootTabBarController sharedController] pushViewController:audiobookVC animated:YES];

      __weak AudiobookPlayerViewController *weakAudiobookVC = audiobookVC;
      [manager setPlaybackCompletionHandler:^{
        NSSet<NSString *> *types = [[NSSet alloc] initWithObjects:ContentTypeFindaway, ContentTypeOpenAccessAudiobook, ContentTypeFeedbooksAudiobook, nil];
        NSArray<NYPLBookAcquisitionPath *> *paths = [NYPLBookAcquisitionPath
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

      NYPLBookLocation *const bookLocation =
      [[NYPLBookRegistry sharedRegistry] locationForIdentifier:book.identifier];

      if (bookLocation) {
        NSData *const data = [bookLocation.locationString dataUsingEncoding:NSUTF8StringEncoding];
        ChapterLocation *const chapterLocation = [ChapterLocation fromData:data];
        NYPLLOG_F(@"Returning to Audiobook Location: %@", chapterLocation);
        [manager.audiobook.player movePlayheadToLocation:chapterLocation];
      }

      [self scheduleTimerForAudiobook:book manager:manager viewController:audiobookVC];
    }];
  }];

}

#pragma mark - Audiobook Methods

- (void)registerCallbackForLogHandler
{
  [DefaultAudiobookManager setLogHandler:^(enum LogLevel level, NSString * _Nonnull message, NSError * _Nullable error) {
    NSString *msg = [NSString stringWithFormat:@"Level: %ld. Message: %@",
                     (long)level, message];

    if (error) {
      [NYPLErrorLogger logAudiobookIssue:error
                                severity:NYPLSeverityError
                                 message:msg];
    } else {
      if (level > LogLevelDebug) {
        NSError *error = [NSError errorWithDomain:@"org.nypl.labs.audiobookToolkit" code:NYPLErrorCodeAudiobookExternalError userInfo:nil];

        NYPLSeverity severity = level == LogLevelInfo ? NYPLSeverityInfo : level == LogLevelWarn ? NYPLSeverityWarning : NYPLSeverityError;
        [NYPLErrorLogger logAudiobookIssue:error
                                  severity:severity
                                   message:msg];
      }
    }
  }];
}

- (void)scheduleTimerForAudiobook:(NYPLBook *)book
                          manager:(id<AudiobookManager>)manager
                   viewController:(AudiobookPlayerViewController *)viewController
{
  self.audiobookViewController = viewController;
  self.book = book;
  self.manager = manager;
  // Target-Selector method required for iOS <10.0
  self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                target:self
                                              selector:@selector(pollAudiobookReadingLocation)
                                              userInfo:nil
                                               repeats:YES];
}

- (void)pollAudiobookReadingLocation
{
  if (!self.audiobookViewController) {
    [self.timer invalidate];
    self.timer = nil;
    self.book = nil;
    self.manager = nil;
    return;
  }

  NSString *const string = [[NSString alloc]
                            initWithData:self.manager.audiobook.player.currentChapterLocation.toData
                            encoding:NSUTF8StringEncoding];
  [[NYPLBookRegistry sharedRegistry]
   setLocation:[[NYPLBookLocation alloc] initWithLocationString:string renderer:@"NYPLAudiobookToolkit"]
   forIdentifier:self.book.identifier];
}

- (void)presentDRMKeyError:(NSError *) error {
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

- (void)presentCorruptedItemErrorForBook:(NYPLBook*)book fromURL:(NSURL*)url
{
  NSString *title = NSLocalizedString(@"Corrupted Audiobook", nil);
  NSString *message = NSLocalizedString(@"The audiobook you are trying to open appears to be corrupted. Try downloading it again.", nil);
  UIAlertController *alert = [NYPLAlertUtils alertWithTitle:title message:message];
  [NYPLAlertUtils presentFromViewControllerOrNilWithAlertController:alert viewController:nil animated:YES completion:nil];

  NSString *logMsg = [NSString stringWithFormat:@"bookID: %@; fileURL: %@", book.identifier, url];
  [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeAudiobookCorrupted
                            summary:@"Audiobooks: corrupted audiobook"
                            message:logMsg
                           metadata:nil];
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

- (void)audiobookManagerDidRequestRefresh {
  if (![self.refreshAudiobookLock tryLock]) {
    return;
  }
    
  [[NYPLBookRegistry sharedRegistry] setState:NYPLBookStateDownloadNeeded forIdentifier:self.book.identifier];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateODAudiobookManifest) name:NYPLMyBooksDownloadCenterDidChangeNotification object:nil];
    
  [[NYPLMyBooksDownloadCenter sharedDownloadCenter] startDownloadForBook:self.book];
}

- (void)updateODAudiobookManifest {
  if ([[NYPLBookRegistry sharedRegistry] stateForIdentifier:self.book.identifier] == NYPLBookStateDownloadSuccessful) {
    OverdriveAudiobook *odAudiobook = (OverdriveAudiobook *)self.manager.audiobook;

    NSURL *const url = [[NYPLMyBooksDownloadCenter sharedDownloadCenter] fileURLForBookIndentifier:self.book.identifier];
    NSData *const data = [NSData dataWithContentsOfURL:url];
    if (data == nil) {
      [self presentCorruptedItemErrorForBook:self.book fromURL:url];
      return;
    }

    id const json = NYPLJSONObjectFromData(data);

    NSMutableDictionary *dict = [(NSMutableDictionary *)json mutableCopy];

    dict[@"id"] = self.book.identifier;

    [odAudiobook updateManifestWithJSON:dict];

    DefaultAudiobookManager *audiobookManager = (DefaultAudiobookManager *)_manager;
    [audiobookManager updateAudiobookWith:odAudiobook.spine];
      
    [[NSNotificationCenter defaultCenter] removeObserver:self];
      
    [self.refreshAudiobookLock unlock];
  }
}

@end
