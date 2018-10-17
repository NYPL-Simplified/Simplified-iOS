@import NYPLAudiobookToolkit;

#import "NYPLAccount.h"
#import "NYPLAccountSignInViewController.h"
#import "NYPLSession.h"
#import "NYPLAlertController.h"
#import "NYPLBook.h"
#import "NYPLBookDownloadFailedCell.h"
#import "NYPLBookDownloadingCell.h"
#import "NYPLBookNormalCell.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLReaderViewController.h"
#import "NYPLRootTabBarController.h"
#import "NYPLSettings.h"
#import "NSURLRequest+NYPLURLRequestAdditions.h"
#import "NYPLJSON.h"

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
    if ((![[NYPLADEPT sharedInstance] isUserAuthorized:[[NYPLAccount sharedAccount] userID]
                                           withDevice:[[NYPLAccount sharedAccount] deviceID]]) &&
        ([[NYPLAccount sharedAccount] hasBarcodeAndPIN])) {
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
    case NYPLBookContentTypeEPUB: {
      [[NYPLRootTabBarController sharedController] pushViewController:[[NYPLReaderViewController alloc] initWithBookIdentifier:book.identifier] animated:YES];
      [NYPLAnnotations requestServerSyncStatusForAccount:[NYPLAccount sharedAccount] completion:^(BOOL enableSync) {
        if (enableSync == YES) {
          Account *currentAccount = [[AccountsManager sharedInstance] currentAccount];
          currentAccount.syncPermissionGranted = enableSync;
        }
      }];
      break;
    }
    case NYPLBookContentTypeAudiobook: {
      NSURL *const url = [[NYPLMyBooksDownloadCenter sharedDownloadCenter] fileURLForBookIndentifier:book.identifier];
      NSData *const data = [NSData dataWithContentsOfURL:url];
      id const json = NYPLJSONObjectFromData(data);
      id<Audiobook> const audiobook = [AudiobookFactory audiobook:json];
      if (audiobook) {
        AudiobookMetadata *const metadata = [[AudiobookMetadata alloc]
                                             initWithTitle:book.title
                                             authors:@[book.authors]
                                             narrators:@[]
                                             publishers:@[book.publisher]
                                             published:book.published
                                             modified:book.published
                                             language:@"English"];
        AudiobookPlayerViewController *const viewController = [[AudiobookPlayerViewController alloc]
                                                               initWithAudiobookManager:[[DefaultAudiobookManager alloc]
                                                                                         initWithMetadata:metadata
                                                                                         audiobook:audiobook]];
        viewController.hidesBottomBarWhenPushed = YES;
        [[NYPLRootTabBarController sharedController]
         pushViewController:viewController
         animated:YES];
      } else {
        // WINNIETODO
      }
    }
    default:
      // WINNIETODO: SHOW ERROR
      break;
  }
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

@end
