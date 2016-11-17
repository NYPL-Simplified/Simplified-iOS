#import "NYPLSession.h"
#import "NYPLBook.h"
#import "NYPLBookAcquisition.h"
#import "NYPLBookDownloadFailedCell.h"
#import "NYPLBookDownloadingCell.h"
#import "NYPLBookNormalCell.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLReaderViewController.h"
#import "NYPLRootTabBarController.h"
#import "NSURLRequest+NYPLURLRequestAdditions.h"

#import "NYPLBookCellDelegate.h"
#import "SimplyE-Swift.h"

#import "BCLUrms/BCLUrmsRegisterBookRequest.h"
#import "BCLUrms/BCLUrmsEvaluateLicenseRequest.h"

@interface NYPLBookCellDelegate () <BCLUrmsEvaluateLicenseRequestDelegate,
BCLUrmsRegisterBookRequestDelegate> {
  
}

@end

@implementation NYPLBookCellDelegate {
  BCLUrmsRegisterBookRequest *m_registerBookRequest;
  BCLUrmsEvaluateLicenseRequest *m_evaluateLicenseRequest;
  NSString *m_bookIdentifier;
}

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
  [NYPLCirculationAnalytics postEvent:@"open_book" withBook:book];
  
  m_bookIdentifier = book.identifier;
  
  /*
   * TEMPORARY HARDCODED CHANGE FOR PROOF OF CONCEPT:
   * Because we cannot put a URMS protected book into the actual catalog of the NYPL,
   * we have to resort to use a hardcoded path to a book that has been purchased in our
   * URMS store. Once we have the OPDS feed delivering URMS protected books, we can get
   * rid of this hardcoded path. In the mean time, you should hardcode a path to whatever
   * book you want to register.
   */
  
  m_registerBookRequest = [[BCLUrmsRegisterBookRequest alloc]
                           initWithDelegate:self
                           ccid:@"NHG6M6VG63D4DQKJMC986FYFDG5MDQJE"
                           profileName:@"default"
                           path:@"/Users/nelson_leme/Documents/Temp/f24e70fab7857857c23a762530eabb7cfb141f49f3bfb9552503aecb4fb69212.epub"];
  
  /*

  [[NYPLRootTabBarController sharedController]
   pushViewController:[[NYPLReaderViewController alloc]
                       initWithBookIdentifier:book.identifier]
   animated:YES];
   */
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

#pragma mark BFRUrmsRegisterBookRequestDelegate

- (void)urmsRegisterBookRequestDidFinish:(nonnull BCLUrmsRegisterBookRequest *)request
                                   error:(nullable NSError *)error
{
  if (error != nil)
  {
    return;
  }
  
  /* TEMPORARY CHANGE FOR PROOF OF CONCEPT:
     Because we don't have an OPDF feed that can give us the CCID of a book yet,
     we had to resort to hardcoding a CCID. Once the OPDS feed gives us the CCID
     for each book, we can make the same exact call in here, but passing something
     like "book.ccid", for example. */
  
  m_evaluateLicenseRequest = [[BCLUrmsEvaluateLicenseRequest alloc]
                              initWithDelegate:self ccid:@"NHG6M6VG63D4DQKJMC986FYFDG5MDQJE" profileName:@"default"];
  
}

#pragma mark BFRUrmsEvaluateLicenseRequestDelegate

- (void)urmsEvaluateLicenseRequestDidFinish:(nonnull BCLUrmsEvaluateLicenseRequest *)request
                                      error:(nullable NSError *)error
{
  if (error != nil)
  {
    return;
  }
  
  [[NYPLRootTabBarController sharedController]
   pushViewController:[[NYPLReaderViewController alloc]
                       initWithBookIdentifier:m_bookIdentifier]
   animated:YES];
  
}


@end
