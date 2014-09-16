#import "NYPLBook.h"
#import "NYPLNull.h"

#import "NYPLBookCoverRegistry.h"

@interface NYPLBookCoverRegistry ()

@property (nonatomic) NSURLSession *session;

@end

static NSUInteger const diskCacheInMegabytes = 16;
static NSUInteger const memoryCacheInMegabytes = 2;

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
  configuration.URLCache.diskCapacity = 1024 * 1024 * diskCacheInMegabytes;
  configuration.URLCache.memoryCapacity = 1024 * 1024 * memoryCacheInMegabytes;
  configuration.URLCredentialStorage = nil;
  
  self.session = [NSURLSession sessionWithConfiguration:configuration];
  
  return self;
}

#pragma mark -

- (void)temporaryThumbnailImageForBook:(NYPLBook *)book handler:(void (^)(UIImage *image))handler
{
  if(!book.imageThumbnailURL) {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      handler(nil);
    }];
    return;
  }
  
  [[self.session
    dataTaskWithRequest:[NSURLRequest requestWithURL:book.imageThumbnailURL]
    completionHandler:^(NSData *const data,
                        __attribute__((unused)) NSURLResponse *response,
                        __attribute__((unused)) NSError *error) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        handler([UIImage imageWithData:data]);
      }];
    }]
   resume];
}

- (void)temporaryThumbnailImagesForBooks:(NSSet *)books
                                 handler:(void (^)(NSDictionary *dictionary))handler
{
  if(!books) {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      handler(nil);
    }];
    return;
  }
  
  if(!books.count) {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      handler(^{});
    }];
    return;
  }
  
  for(id const object in books) {
    if(![object isKindOfClass:[NYPLBook class]]) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        handler(nil);
      }];
      return;
    }
  }
  
  NSLock *const lock = [[NSLock alloc] init];
  NSMutableDictionary *const dictionary = [NSMutableDictionary dictionary];
  __block NSUInteger remaining = books.count;
  
  for(NYPLBook *const book in books) {
    if(!book.imageThumbnailURL) {
      dictionary[book.identifier] = [NSNull null];
      continue;
    }
    [[self.session
      dataTaskWithRequest:[NSURLRequest requestWithURL:book.imageThumbnailURL]
      completionHandler:^(NSData *const data,
                          __attribute__((unused)) NSURLResponse *response,
                          __attribute__((unused)) NSError *error) {
        [lock lock];
        dictionary[book.identifier] = NYPLNullFromNil([UIImage imageWithData:data]);
        --remaining;
        if(!remaining) {
          [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            handler(dictionary);
          }];
        }
        [lock unlock];
      }]
     resume];
  }
}

@end
