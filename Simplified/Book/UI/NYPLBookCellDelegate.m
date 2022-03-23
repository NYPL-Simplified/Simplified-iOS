@import PDFRendererProvider;

#if FEATURE_AUDIOBOOKS
#import "NYPLBookCellDelegate+Audiobooks.h"
#endif

#import "NYPLBook.h"
#import "NYPLBookDownloadFailedCell.h"
#import "NYPLBookDownloadingCell.h"
#import "NYPLBookLocation.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLRootTabBarController.h"
#import "NYPLBookCellDelegate.h"
#import "SimplyE-Swift.h"

#if defined(FEATURE_DRM_CONNECTOR)
#import <ADEPT/ADEPT.h>
#endif

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
#if FEATURE_AUDIOBOOKS
  _audiobookProgressSavingQueue = dispatch_queue_create("org.nypl.labs.SimplyE.BookCellDelegate.audiobookProgressSavingQueue", nil);
#endif
  
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
#if FEATURE_DRM_CONNECTOR
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
    [reauthenticator authenticateIfNeededUsingExistingCredentials:YES
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
#endif//FEATURE_DRM_CONNECTOR
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
#if FEATURE_AUDIOBOOKS
    case NYPLBookContentTypeAudiobook:
      [self openAudiobook:book];
      break;
#endif
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

- (void)presentUnsupportedItemError
{
  NSString *title = NSLocalizedString(@"Unsupported Item", nil);
  NSString *message = NSLocalizedString(@"The item you are trying to open is not currently supported.", nil);
  UIAlertController *alert = [NYPLAlertUtils alertWithTitle:title message:message];
  [NYPLAlertUtils presentFromViewControllerOrNilWithAlertController:alert viewController:nil animated:YES completion:nil];
}


#pragma mark - NYPLBookDownloadFailedDelegate

- (void)didSelectCancelForBookDownloadFailedCell:(NYPLBookDownloadFailedCell *const)cell
{
  [[NYPLMyBooksDownloadCenter sharedDownloadCenter]
   cancelDownloadForBookIdentifier:cell.book.identifier];
}

- (void)didSelectTryAgainForBookDownloadFailedCell:(NYPLBookDownloadFailedCell *const)cell
{
  [[NYPLMyBooksDownloadCenter sharedDownloadCenter] startDownloadForBook:cell.book];
}

#pragma mark - NYPLBookDownloadingCellDelegate

- (void)didSelectCancelForBookDownloadingCell:(NYPLBookDownloadingCell *const)cell
{
  [[NYPLMyBooksDownloadCenter sharedDownloadCenter]
   cancelDownloadForBookIdentifier:cell.book.identifier];
}


@end
