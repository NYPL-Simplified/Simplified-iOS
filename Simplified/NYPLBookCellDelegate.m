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

#import "NYPLBookCellDelegate.h"
#import "SimplyE-Swift.h"

#if defined(FEATURE_DRM_CONNECTOR)
#import <ADEPT/ADEPT.h>
#endif

@import DITAURMS;

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
  if (book.ccid) {
    NSString* path = [[[NYPLMyBooksDownloadCenter sharedDownloadCenter]
                       fileURLForBookIndentifier:book.identifier] path];
    NYPLLOG_F(@"path - %@", path);

    Account *currentAccount = [[NYPLSettings sharedSettings] currentAccount];
    NYPLAccount *account = [NYPLAccount sharedAccount];
    NSString *user = account.barcode;
    NYPLLOG_F(@"user - %@", user);

    NSString *password = account.PIN;
    NYPLLOG_F(@"password - %@", password);

    NSString *abbreviation = currentAccount.abbreviation;
    NYPLLOG_F(@"abbreviation - %@", abbreviation);

    NSString *tokenUrl = account.licensor[@"clientTokenUrl"];
    NYPLLOG_F(@"tokenUrl - %@", tokenUrl);
    
    NSString *ccid = book.ccid;
    NYPLLOG_F(@"ccid - %@", ccid);

    if (user) {
      // URMS evaluate Book license
      [DITAURMS evaluateBookWithCcid:ccid
                                path:path
                         profileName:abbreviation
                                user:user
                            password:password
                            tokenUrl:tokenUrl
                         showLoading:true
                            callback:^(DITAURMSCallback callback) {
                              switch (callback) {
                                case DITAURMSCallbackSuccess:
                                  NYPLLOG(@"AMURMSCallbackSuccess - evaluateLicenseWithCcid");
                                  [self openBook:book];
                                  break;
                                case DITAURMSCallbackFailure:
                                  NYPLLOG(@"AMURMSCallbackFailure - evaluateLicenseWithCcid");
                                  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                    [[NSNotificationCenter defaultCenter]
                                     postNotificationName:@"URMSFailed"
                                     object:nil
                                     userInfo:nil];
                                  }];
                                  
                                  break;
                              }
                            }];
    }
  }
  else {
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
    }
}

- (void)openBook:(NYPLBook *)book
{
  [NYPLCirculationAnalytics postEvent:@"open_book" withBook:book];
  [[NYPLRootTabBarController sharedController]
   pushViewController:[[NYPLReaderViewController alloc]
                       initWithBookIdentifier:book.identifier]
   animated:YES];
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
