#import "NYPLAsync.h"

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

- (void)withURL:(NSURL *const)URL completionHandler:(void (^)(NSData *data))handler
{
  [[self.session
    dataTaskWithURL:URL
    completionHandler:^(NSData *const data,
                        __attribute__((unused)) NSURLResponse *response,
                        NSError *const error) {
      if(error) {
        handler(nil);
        return;
      }
      
      handler(data);
    }]
   resume];
}

- (void)withURLs:(NSSet *const)URLs handler:(void (^)(NSDictionary *dataDictionary))handler
{
  if(!URLs.count) {
    NYPLAsyncDispatch(^{handler(@{});});
    return;
  }
  
  for(id const object in URLs) {
    if(![object isKindOfClass:[NSURL class]]) {
      @throw NSInvalidArgumentException;
    }
  }
  
  NSLock *const lock = [[NSLock alloc] init];
  NSMutableDictionary *const dataDictionary = [NSMutableDictionary dictionary];
  __block NSUInteger remaining = URLs.count;
  
  for(NSURL *const URL in URLs) {
    [self withURL:URL completionHandler:^(NSData *const data) {
      [lock lock];
      dataDictionary[URL] = (data ? data : [NSNull null]);
      --remaining;
      if(!remaining) {
        NYPLAsyncDispatch(^{handler(dataDictionary);});
      }
      [lock unlock];
    }];
  }
}

- (NSData *)cachedDataForURL:(NSURL *)URL
{
  return [self.session.configuration.URLCache
           cachedResponseForRequest:[NSURLRequest requestWithURL:URL]].data;
}

@end
