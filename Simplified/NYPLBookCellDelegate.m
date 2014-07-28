#import "NYPLAccount.h"
#import "NYPLBook.h"
#import "NYPLBookDownloadFailedCell.h"
#import "NYPLBookDownloadingCell.h"
#import "NYPLBookNormalCell.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLMyBooksRegistry.h"
#import "NYPLRootTabBarController.h"
#import "NYPLSettingsCredentialViewController.h"

#import "NYPLBookCellDelegate.h"

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

#pragma mark NYPLBookNormalCellDelegate

- (void)didSelectDeleteForBookNormalCell:(__attribute__((unused)) NYPLBookNormalCell *)cell
{
  // TODO
}

- (void)didSelectDownloadForBookNormalCell:(NYPLBookNormalCell *const)cell
{
  NYPLBook *const book = cell.book;
  
  if([NYPLAccount sharedAccount].hasBarcodeAndPIN) {
    [[NYPLMyBooksDownloadCenter sharedDownloadCenter] startDownloadForBook:book];
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

- (void)didSelectReadForBookNormalCell:(__attribute__((unused)) NYPLBookNormalCell *)cell
{
  // TODO
}

#pragma mark NYPLBookDownloadFailedDelegate

- (void)didSelectCancelForBookDownloadFailedCell:(NYPLBookDownloadFailedCell *)cell
{
  [[NYPLMyBooksRegistry sharedRegistry]
   setState:NYPLMyBooksStateDownloadNeeded forIdentifier:cell.book.identifier];
}

- (void)didSelectTryAgainForBookDownloadFailedCell:(NYPLBookDownloadFailedCell *)cell
{
  [[NYPLMyBooksDownloadCenter sharedDownloadCenter] startDownloadForBook:cell.book];
}

#pragma mark NYPLBookDownloadingCellDelegate

- (void)didSelectCancelForBookDownloadingCell:(NYPLBookDownloadingCell *)cell
{
  [[NYPLMyBooksDownloadCenter sharedDownloadCenter]
   cancelDownloadForBookIdentifier:cell.book.identifier];
}

@end
