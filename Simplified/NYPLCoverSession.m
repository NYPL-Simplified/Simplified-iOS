#import "NYPLCoverSession.h"

@interface NYPLCoverSession ()

@property (nonatomic) NSURLSession *session;

@end

static NSUInteger const diskCacheInMegabytes = 20;
static NSUInteger const memoryCacheInMegabytes = 2;

static NYPLCoverSession *sharedCoverSession = nil;

@implementation NYPLCoverSession

+ (NYPLCoverSession *)sharedSession
{
  static dispatch_once_t predicate;
  
  dispatch_once(&predicate, ^{
    sharedCoverSession = [[NYPLCoverSession alloc] init];
    if(!sharedCoverSession) {
      NYPLLOG(@"Failed to create shared session.");
    }
  });
  
  return sharedCoverSession;
}

#pragma mark NSObject

- (instancetype)init
{
  if(sharedCoverSession) {
    @throw NSGenericException;
  }
  
  self = [super init];
  if(!self) return nil;
  
  NSURLSessionConfiguration *const configuration =
    [NSURLSessionConfiguration defaultSessionConfiguration];
  
  assert(configuration.URLCache);
  
  configuration.URLCache.diskCapacity = 1024 * 1024 * diskCacheInMegabytes;
  configuration.URLCache.memoryCapacity = 1024 * 1024 * memoryCacheInMegabytes;
  
  self.session = [NSURLSession sessionWithConfiguration:configuration];
  
  return self;
}

#pragma mark -

- (void)withURL:(NSURL *const)url completionHandler:(void (^)(UIImage *image))handler
{
  [[self.session
    dataTaskWithURL:url
    completionHandler:^(NSData *const data,
                        __attribute__((unused)) NSURLResponse *response,
                        __attribute__((unused)) NSError *const error) {
      handler([UIImage imageWithData:data]);
    }]
   resume];
}

- (UIImage *)cachedImageForURL:(NSURL *)url
{
  return [UIImage imageWithData:
          [self.session.configuration.URLCache
           cachedResponseForRequest:[NSURLRequest requestWithURL:url]].data];
}

@end
