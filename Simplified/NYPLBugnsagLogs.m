@import Bugsnag;

#import <Foundation/Foundation.h>
#import "NYPLBugsnagLogs.h"

#import "SimplyE-Swift.h"
#import "NYPLBook.h"
#import "NYPLBookLocation.h"
#import "NYPLReaderRenderer.h"
#import "NYPLReaderReadiumView.h"


/// Remove any of these logs if they no longer make any sense, have been fixed, or have been forgotten.
@implementation NYPLBugsnagLogs

+ (void)recordUnexpectedNilIdentifierForBook:(NYPLBook *)book identifier:(NSString *)identifier title:(NSString *)bookTitle {

  if (!book.identifier) {

    NSMutableDictionary *metadataParams = [NSMutableDictionary dictionary];
    [metadataParams setObject:[[AccountsManager sharedInstance] currentAccount] forKey:@"currentAccount"];
    if (identifier) [metadataParams setObject:identifier forKey:@"incomingIdentifierString"];
    if (bookTitle) [metadataParams setObject:bookTitle forKey:@"bookTitle"];
    if (book.revokeURL.absoluteString) [metadataParams setObject:book.revokeURL.absoluteString forKey:@"revokeLink"];

    [Bugsnag notifyError:[NSError errorWithDomain:@"org.nypl.labs.SimplyE" code:2 userInfo:nil]
                   block:^(BugsnagCrashReport * _Nonnull report) {
                     report.context = @"NYPLMyBooksDownloadCenter";
                     report.severity = BSGSeverityWarning;
                     report.errorMessage = @"The book identifier was unexpectedly nil when attempting to return.";
                     [report addMetadata:metadataParams toTabWithName:@"Extra Data"];
                   }];
  }
}

+ (void)recordFailureToCopy:(NYPLBook *)book
{
  NSMutableDictionary *metadataParams = [NSMutableDictionary dictionary];
  [metadataParams setObject:[[AccountsManager sharedInstance] currentAccount] forKey:@"currentAccount"];
  if (book.title) [metadataParams setObject:book.title forKey:@"bookTitle"];
  if (book.identifier) [metadataParams setObject:book.identifier forKey:@"bookIdentifier"];

  [Bugsnag notifyError:[NSError errorWithDomain:@"org.nypl.labs.SimplyE" code:5 userInfo:nil]
                 block:^(BugsnagCrashReport * _Nonnull report) {
                   report.context = @"NYPLMyBooksDownloadCenter";
                   report.severity = BSGSeverityWarning;
                   report.errorMessage = @"fileURLForBookIndentifier returned nil, so no destination to copy file to.";
                   [report addMetadata:metadataParams toTabWithName:@"Extra Data"];
                 }];
}

+ (void)reportNilUrlToBugsnagWithBaseHref:(NSString *)href rootURL:(NSString *)url bookID:(NSString *)bookID
{
  NSMutableDictionary *metadataParams = [NSMutableDictionary dictionary];
  if (url) [metadataParams setObject:url forKey:@"packageRootUrl"];
  if (href) [metadataParams setObject:href forKey:@"spineItemBaseHref"];
  if (bookID) [metadataParams setObject:bookID forKey:@"bookIdentifier"];

  [Bugsnag notifyError:[NSError errorWithDomain:@"org.nypl.labs.SimplyE" code:1 userInfo:nil]
                 block:^(BugsnagCrashReport * _Nonnull report) {
                   report.context = @"NYPLReaderReadiumView";
                   report.severity = BSGSeverityInfo;
                   report.errorMessage = @"URL for creating book length was unexpectedly nil";
                   [report addMetadata:metadataParams toTabWithName:@"Extra Data"];
                 }];
}

+ (void)reportNilContentCFIToBugsnag:(NYPLBookLocation *)location locationDictionary:(NSDictionary *)locationDictionary bookID:(NSString *)bookID title:(NSString *)title {
  NSMutableDictionary *metadataParams = [NSMutableDictionary dictionary];
  if (bookID) [metadataParams setObject:bookID forKey:@"bookID"];
  if (title) [metadataParams setObject:title forKey:@"bookTitle"];
  if (location.locationString) [metadataParams setObject:location.locationString forKey:@"registry locationString"];
  if (location.renderer) [metadataParams setObject:location.renderer forKey:@"renderer"];
  if (locationDictionary[@"idref"]) [metadataParams setObject:locationDictionary[@"idref"] forKey:@"openPageRequest idref"];

  [Bugsnag notifyError:[NSError errorWithDomain:@"org.nypl.labs.SimplyE" code:0 userInfo:nil]
                 block:^(BugsnagCrashReport * _Nonnull report) {
                   report.context = @"NYPLReaderReadiumView";
                   report.severity = BSGSeverityWarning;
                   report.groupingHash = @"open-book-nil-cfi";
                   report.errorMessage = @"No CFI parsed from NYPLBookLocation, or Readium failed to generate a CFI.";
                   [report addMetadata:metadataParams toTabWithName:@"Extra CFI Data"];
                 }];
}

+ (void)deauthorizationError {
  // TODO: Remote logging can be removed when it is determined that sufficient data has been collected.
  NYPLLOG(@"Failed to deauthorize successfully. User will lose an activation on this device.");
  [Bugsnag notifyError:[NSError errorWithDomain:@"org.nypl.labs.SimplyE" code:4 userInfo:nil]
                 block:^(BugsnagCrashReport * _Nonnull report) {
                   report.context = @"NYPLSettingsAccountDetailViewController";
                   report.severity = BSGSeverityInfo;
                   report.errorMessage = @"User has lost an activation on signout due to NYPLAdept Error.";
                 }];
}

+ (void)loginAlertError:(NSError *)error code:(NSInteger)code libraryName:(NSString *)name {

  //FIXME: Remove Bugsnag log when DRM Activation moves to the auth document
  if ([error.domain isEqual:NSURLErrorDomain]) {
    NSMutableDictionary *metadataParams = [NSMutableDictionary dictionary];
    if (name) [metadataParams setObject:name forKey:@"libraryName"];
    if (code) [metadataParams setObject:[NSNumber numberWithInteger:code] forKey:@"errorCode"];
    [Bugsnag notifyError:[NSError errorWithDomain:@"org.nypl.labs.SimplyE" code:10 userInfo:nil]
                   block:^(BugsnagCrashReport * _Nonnull report) {
                     report.severity = BSGSeverityInfo;
                     report.errorMessage = @"Login Failed With Error";
                     [report addMetadata:metadataParams toTabWithName:@"Library Info"];
                   }];
  }
}

+ (void)bugsnagLogInvalidLicensorWithAccountType:(NSInteger)type
{
  [Bugsnag notifyError:[NSError errorWithDomain:@"org.nypl.labs.SimplyE" code:3 userInfo:nil]
                 block:^(BugsnagCrashReport * _Nonnull report) {
                   report.context = @"NYPLSettingsAccountDetailViewController";
                   report.severity = BSGSeverityWarning;
                   report.errorMessage = @"No Valid Licensor available to deauthorize device. Signing out NYPLAccount credentials anyway with no message to the user.";
                   NSDictionary *metadata = @{@"accountTypeID" : @(type)};
                   [report addMetadata:metadata toTabWithName:@"Extra Data"];
                 }];
}

+ (void)reportNewActiveSession
{
  NSMutableDictionary *metadataParams = [NSMutableDictionary dictionary];
  NSString *name = [AccountsManager sharedInstance].currentAccount.name;
  if (name) [metadataParams setObject:name forKey:@"libraryName"];

  [Bugsnag notifyError:[NSError errorWithDomain:@"org.nypl.labs.SimplyE" code:9 userInfo:nil]
                 block:^(BugsnagCrashReport * _Nonnull report) {
                   report.severity = BSGSeverityInfo;
                   report.groupingHash = @"simplye-app-launch";
                   [report addMetadata:metadataParams toTabWithName:@"Library Info"];
                 }];
}

+ (void)reportExpiredBackgroundFetch {
  NSInteger libraryID = AccountsManager.shared.currentAccount.id;
  NSString *exceptionName = [NSString stringWithFormat:@"BackgroundFetchExpired-Library-%ld", (long)libraryID];
  NSException *exception = [[NSException alloc] initWithName:exceptionName reason:nil userInfo:nil];
  NSMutableDictionary *metadataParams = [NSMutableDictionary dictionary];
  if (libraryID) [metadataParams setObject:[NSNumber numberWithInteger:libraryID] forKey:@"Library"];
  [Bugsnag notify:exception block:^(BugsnagCrashReport * _Nonnull report) {
    report.groupingHash = exceptionName;
    report.severity = BSGSeverityWarning;
    [report addMetadata:metadataParams toTabWithName:@"Extra Info"];
  }];
}

+ (void)logExceptionToBugsnag:(NSException *)exception library:(NSString *)library
{
  [Bugsnag notifyError:[NSError errorWithDomain:@"org.nypl.labs.SimplyE" code:8 userInfo:nil]
                 block:^(BugsnagCrashReport * _Nonnull report) {
                   report.context = @"NYPLZXingEncoder";
                   report.severity = BSGSeverityInfo;
                   report.errorMessage = [NSString stringWithFormat:@"%@: %@. %@", library, exception.name, exception.reason];
                 }];
}

+ (void)catalogLoadError:(NSError *)error URL:(NSURL *)url
{
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  if (url) [dict setObject:url forKey:@"URL"];
  [Bugsnag notifyError:error block:^(BugsnagCrashReport * _Nonnull report) {
    report.groupingHash = @"catalog-load-error";
    report.metaData = dict;
  }];
}

@end
