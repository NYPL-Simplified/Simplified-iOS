#import "NYPLAsync.h"
#import "NYPLBook.h"

#import "NYPLBookCoverRegistry.h"

@interface NYPLBookCoverRegistry ()

@property (nonatomic) NSURLSession *session;

@end

@implementation NYPLBookCoverRegistry

+ (NYPLBookCoverRegistry *)sharedRegistry
{
  static dispatch_once_t predicate;
  static NYPLBookCoverRegistry *sharedRegistry = nil;
  
  dispatch_once(&predicate, ^{
    sharedRegistry = [[self alloc] init];
    if(!sharedRegistry) {
      NYPLLOG(@"Failed to create shared registry.");
    }
  });
  
  return sharedRegistry;
}

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  NSURLSessionConfiguration *const configuration =
    [NSURLSessionConfiguration defaultSessionConfiguration];
  
  configuration.HTTPCookieStorage = nil;
  configuration.HTTPMaximumConnectionsPerHost = 8;
  configuration.HTTPShouldUsePipelining = YES;
  configuration.timeoutIntervalForRequest = 5.0;
  configuration.timeoutIntervalForResource = 20.0;
  configuration.URLCredentialStorage = nil;
  
  self.session = [NSURLSession sessionWithConfiguration:configuration];
  
  return self;
}

#pragma mark -

- (void)temporaryThumbnailImageForBook:(NYPLBook *)book handler:(void (^)(UIImage *image))handler
{
  if(!book.imageThumbnailURL) {
    NYPLAsyncDispatch(^{
      handler(nil);
    });
  }
  
  // TODO
}

@end
