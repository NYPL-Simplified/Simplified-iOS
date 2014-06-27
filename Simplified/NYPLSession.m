#import "NYPLSession.h"

@interface NYPLSession ()

@property (nonatomic) NSURLSession *session;

@end

static NSUInteger const diskCacheInMegabytes = 20;
static NSUInteger const memoryCacheInMegabytes = 2;

static NYPLSession *sharedSession = nil;

@implementation NYPLSession

+ (NYPLSession *)sharedSession
{
  static dispatch_once_t predicate;
  
  dispatch_once(&predicate, ^{
    sharedSession = [[NYPLSession alloc] init];
    if(!sharedSession) {
      NYPLLOG(@"Failed to create shared session.");
    }
  });
  
  return sharedSession;
}

#pragma mark NSObject

- (instancetype)init
{
  if(sharedSession) {
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

- (void)withURL:(NSURL *const)url completionHandler:(void (^)(NSData *data))handler
{
  [[self.session
    dataTaskWithURL:url
    completionHandler:^(NSData *const data,
                        __attribute__((unused)) NSURLResponse *response,
                        __attribute__((unused)) NSError *const error) {
      handler(data);
    }]
   resume];
}

- (NSData *)cachedDataForURL:(NSURL *)url
{
  return [self.session.configuration.URLCache
           cachedResponseForRequest:[NSURLRequest requestWithURL:url]].data;
}

@end
