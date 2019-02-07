@class NYPLBook;
@class NYPLBookLocation;

@interface NYPLBugsnagLogs : NSObject

+ (void)recordUnexpectedNilIdentifierForBook:(NYPLBook *)book identifier:(NSString *)identifier title:(NSString *)bookTitle;

+ (void)recordFailureToCopy:(NYPLBook *)book;

+ (void)reportNilUrlToBugsnagWithBaseHref:(NSString *)href rootURL:(NSString *)url bookID:(NSString *)bookID;

+ (void)reportNilContentCFIToBugsnag:(NYPLBookLocation *)location locationDictionary:(NSDictionary *)locationDictionary bookID:(NSString *)bookID title:(NSString *)title;

+ (void)deauthorizationError;

+ (void)loginAlertError:(NSError *)error code:(NSInteger)code libraryName:(NSString *)name;

+ (void)bugsnagLogInvalidLicensorWithAccountType:(NSInteger)type;

+ (void)reportNewActiveSession;

+ (void)reportExpiredBackgroundFetch;

+ (void)logExceptionToBugsnag:(NSException *)exception library:(NSString *)library;

+ (void)catalogLoadError:(NSError *)error URL:(NSURL *)url;

@end
