#import "NYPLSession.h"
#import "NYPLAlertController.h"
#import "NYPLBook.h"
#import "NYPLBookAcquisition.h"
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
  NYPLSettings *settings = [NYPLSettings sharedSettings];
  
  if ([[settings currentAccount] needsAuth] == YES || [settings userAboveAge]) {
    [[NYPLMyBooksDownloadCenter sharedDownloadCenter] startDownloadForBook:book];
  } else if ([[settings currentAccount] needsAuth] == NO) {
    [self performAgeCheck:^(BOOL aboveAge) {
      if (aboveAge) {
        [settings setUserAboveAge:YES];
        [[NYPLMyBooksDownloadCenter sharedDownloadCenter] startDownloadForBook:book];
      } else {
        [settings setUserAboveAge:NO];
      }
    }];
  }
}

- (void)didSelectReadForBook:(NYPLBook *)book
{
  [NYPLCirculationAnalytics postEvent:@"open_book" withBook:book];
  [[NYPLRootTabBarController sharedController]
   pushViewController:[[NYPLReaderViewController alloc]
                       initWithBookIdentifier:book.identifier]
   animated:YES];
}

- (void)didSelectReportForBook:(NYPLBook *)book sender:(UIButton *)sender
{
  NYPLProblemReportViewController *problemVC = [[NYPLProblemReportViewController alloc] initWithNibName:@"NYPLProblemReportViewController" bundle:nil];
  BOOL isIPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
  problemVC.modalPresentationStyle = isIPad ? UIModalPresentationPopover : UIModalPresentationOverCurrentContext;
  problemVC.popoverPresentationController.sourceView = sender;
  problemVC.popoverPresentationController.sourceRect = ((UIView *)sender).bounds;
  problemVC.book = book;
  problemVC.delegate = self;
  [[NYPLRootTabBarController sharedController] safelyPresentViewController:problemVC animated:YES completion:nil];
}

- (void)performAgeCheck:(void (^)(BOOL))completion
{
  NYPLAlertController *alertCont = [NYPLAlertController
                                  alertControllerWithTitle:NSLocalizedString(@"Age Verification", @"An alert title indicating the user needs to verify their age")
                                  message:NSLocalizedString(@"You must be 13 years of age or older to download a book from the collection. How old are you?",
                                                            @"An alert message telling the user they must be at least 13 years old and asking how old they are")
                                  preferredStyle:UIAlertControllerStyleAlert];
  
  [alertCont addAction: [UIAlertAction actionWithTitle:NSLocalizedString(@"Under 13", comment: @"A button title indicating an age range")
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * _Nonnull __unused action) {
                                                 if (completion) { completion(NO); }
                                               }]];
  
  [alertCont addAction: [UIAlertAction actionWithTitle:NSLocalizedString(@"13 or Older", comment: @"A button title indicating an age range")
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * _Nonnull __unused action) {
                                                 if (completion) { completion(YES); }
                                               }]];

  [alertCont presentFromViewControllerOrNil:nil animated:YES completion:nil];
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

#pragma mark NYPLProblemReportViewControllerDelegate

- (void)problemReportViewController:(NYPLProblemReportViewController *)problemReportViewController didSelectProblemWithType:(NSString *)type
{
  NSURL *reportURL = problemReportViewController.book.acquisition.report;
  if (reportURL) {
    NSURLRequest *r = [NSURLRequest postRequestWithProblemDocument:@{@"type":type} url:reportURL];
    [[NYPLSession sharedSession] uploadWithRequest:r completionHandler:nil];
  }
  [problemReportViewController dismissViewControllerAnimated:YES completion:^{
    [[NSNotificationCenter defaultCenter] postNotificationName:NYPLBookProblemReportedNotification object:problemReportViewController.book];
  }];
}

@end
