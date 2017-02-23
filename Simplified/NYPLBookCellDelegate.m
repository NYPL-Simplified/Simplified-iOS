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

@import BCLUrms;
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonHMAC.h>

#import "NYPLBookCellDelegate.h"
#import "SimplyE-Swift.h"

@interface NYPLBookCellDelegate () <
  BCLUrmsCreateProfileRequestDelegate,
  BCLUrmsEvaluateRequestDelegate>

@property (nonatomic, strong) NSString *bookIdentifier;
@property (nonatomic, strong) BCLUrmsCreateProfileRequest *createProfileRequest;
@property (nonatomic, assign) BOOL didAttemptToCreateProfile;
@property (nonatomic, strong) BCLUrmsEvaluateRequest *evaluateRequest;

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
  /*
   * TEMPORARY HARDCODED CHANGE FOR PROOF OF CONCEPT:
   * Because we cannot put a URMS protected book into the actual catalog of the NYPL,
   * we have to resort to use a hardcoded path to a book that has been purchased in our
   * URMS store. Once we have the OPDS feed delivering URMS protected books, we can get
   * rid of this.
   */

  self.bookIdentifier = book.identifier;
  self.createProfileRequest = nil;
  self.didAttemptToCreateProfile = NO;
  self.evaluateRequest = nil;

  NSURL *bookURL = [[NSBundle mainBundle] URLForResource:@"UrmsSample.epub" withExtension:nil];

  self.evaluateRequest = [[BCLUrmsEvaluateRequest alloc] initWithDelegate:self
    ccid:@"NHG6M6VG63D4DQKJMC986FYFDG5MDQJE" profileName:@"default" path:bookURL.path];

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

#pragma mark URMS

- (void)urmsCreateProfile {
  NSString *userId = @"google-110495186711904557779";
  NSString *path = [NSString stringWithFormat:@"/store/v2/users/%@/authtoken/generate", userId];
  NSString *sessionUrl = [NSString stringWithFormat:@"http://urms-967957035.eu-west-1.elb.amazonaws.com%@", path];

  long timestamp = [[NSDate date] timeIntervalSince1970];
  NSString *strTimestamp = [NSString stringWithFormat:@"%ld", timestamp];
  NSString *hmacMessage = [NSString stringWithFormat:@"%@%@", path, strTimestamp];
  NSData *message = [hmacMessage dataUsingEncoding:NSUTF8StringEncoding];
  NSString *strSecretkey = @"ucj0z3uthspfixtba5kmwewdgl7s1prm";
  NSData *secretKey = [strSecretkey dataUsingEncoding:NSUTF8StringEncoding];

  uint8_t hashBytes[CC_SHA256_DIGEST_LENGTH];
  memset(hashBytes, 0, CC_SHA256_DIGEST_LENGTH);
  CCHmac(kCCHmacAlgSHA256, secretKey.bytes, secretKey.length, message.bytes, message.length, hashBytes);
  NSData *hmac = [NSData dataWithBytes:hashBytes length:CC_SHA256_DIGEST_LENGTH];
  NSString *authHash = [hmac base64EncodedStringWithOptions:0];

  NSString *storeId = @"129";
  NSString *authString = [NSString stringWithFormat:@"%@-%@-%@", storeId, strTimestamp, authHash];

  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:sessionUrl]];
  [request setHTTPMethod:@"POST"];
  [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
  NSString *postString = [NSString stringWithFormat:@"authString=%@&timestamp=%@", authString, strTimestamp];
  NSData *postData = [postString dataUsingEncoding:NSUTF8StringEncoding];
  [request setHTTPBody:postData];
  [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[postData length]] forHTTPHeaderField:@"Content-Length"];

  NSURLSession *session = [NSURLSession sessionWithConfiguration:
    [NSURLSessionConfiguration ephemeralSessionConfiguration]];

  NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:
    ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
  {
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (dict != nil && [dict isKindOfClass:[NSDictionary class]]) {

      // ISSUE: sometimes the request for a URMS authorization token is failing.
      // The problem seems to be related to the timestamp. I think that the way we
      // were truncating the timestamp is messing up things. However, this only
      // happens occasionally, and given that this is strictly temporary code, it is 
      // not worthy investigating that now. So, if you see that "authToken" is coming
      // up empty, it's because the request failed. Just try again and you should get
      // a token.

      NSString *authToken = [dict objectForKey:@"authToken"];
      if (authToken != nil) {
        self.createProfileRequest = [[BCLUrmsCreateProfileRequest alloc] initWithDelegate:self
          authToken:authToken profileName:@"default"];
      }
    }
  }];

  [task resume];
  [session finishTasksAndInvalidate];
}

- (void)urmsCreateProfileRequestDidFinish:(BCLUrmsCreateProfileRequest *)request error:(NSError *)error {
  NSURL *bookURL = [[NSBundle mainBundle] URLForResource:@"UrmsSample.epub" withExtension:nil];
  self.evaluateRequest = [[BCLUrmsEvaluateRequest alloc] initWithDelegate:self
    ccid:@"NHG6M6VG63D4DQKJMC986FYFDG5MDQJE" profileName:@"default" path:bookURL.path];
  self.createProfileRequest = nil;
}

- (void)urmsEvaluateRequestDidFinish:(BCLUrmsEvaluateRequest *)request error:(NSError *)error {
  if (error == nil) {
    NYPLReaderViewController *vc = [[NYPLReaderViewController alloc]
      initWithBookIdentifier:self.bookIdentifier];
    [[NYPLRootTabBarController sharedController] pushViewController:vc animated:YES];
  }
  else if ([error.domain isEqualToString:BCLUrmsErrorDomain]) {
    if (self.didAttemptToCreateProfile) {
      NSLog(@"%@", error);
	}
	else {
	  self.didAttemptToCreateProfile = YES;
      [self urmsCreateProfile];
	}
  }
  else {
    NSLog(@"%@", error);
  }
  self.evaluateRequest = nil;
}

@end
