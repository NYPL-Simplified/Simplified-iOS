#import "NSString+NYPLStringAdditions.h"
#import "NYPLBook.h"
#import "NYPLNull.h"
#import "NYPLTenPrintCoverView+NYPLTenPrintCoverView_NYPLImageAdditions.h"

#import "NYPLMyBooksCoverRegistry.h"

@interface NYPLMyBooksCoverRegistry ()

@property (nonatomic) NSMutableSet *pinnedBookIdentifiers;
@property (nonatomic) NSURLSession *session;

@end

static NSUInteger const diskCacheInMegabytes = 16;
static NSUInteger const memoryCacheInMegabytes = 2;

@implementation NYPLMyBooksCoverRegistry

+ (NYPLMyBooksCoverRegistry *)sharedRegistry
{
  static dispatch_once_t predicate;
  static NYPLMyBooksCoverRegistry *sharedRegistry = nil;
  
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
  
  NSArray *const URLs =
    [[NSFileManager defaultManager]
     contentsOfDirectoryAtURL:[self pinnedThumbnailImageDirectoryURL]
     includingPropertiesForKeys:@[]
     options:NSDirectoryEnumerationSkipsHiddenFiles
     error:NULL];
  
  self.pinnedBookIdentifiers = [NSMutableSet setWithCapacity:[URLs count]];
  
  for(NSURL *const URL in URLs) {
    [self.pinnedBookIdentifiers addObject:
     [[URL lastPathComponent] fileSystemSafeBase64DecodedStringUsingEncoding:NSUTF8StringEncoding]];
   }
  
  return self;
}

#pragma mark -

- (NSURL *)pinnedThumbnailImageDirectoryURL
{
  NSArray *const paths =
    NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
  
  assert([paths count] == 1);
  
  NSString *const path = paths[0];
  
  NSURL *const URL =
    [[[NSURL fileURLWithPath:path]
      URLByAppendingPathComponent:[[NSBundle mainBundle]
                                   objectForInfoDictionaryKey:@"CFBundleIdentifier"]]
     URLByAppendingPathComponent:@"pinned-thumbnail-images"];
  
  @synchronized(self) {
    if(![[NSFileManager defaultManager]
         createDirectoryAtURL:URL
         withIntermediateDirectories:YES
         attributes:nil
         error:NULL]) {
      NYPLLOG(@"Failed to create directory.");
      return nil;
    }
  }
  
  return URL;
}

- (NSURL *)URLForPinnedThumbnailImageOfBookIdentifier:(NSString *const)bookIdentifier
{
  return [[self pinnedThumbnailImageDirectoryURL] URLByAppendingPathComponent:
          [bookIdentifier fileSystemSafeBase64EncodedStringUsingEncoding:NSUTF8StringEncoding]];
}

- (void)thumbnailImageForBook:(NYPLBook *)book handler:(void (^)(UIImage *image))handler
{
  BOOL isPinned;
  @synchronized(self) {
    isPinned = [self.pinnedBookIdentifiers containsObject:book.identifier];
  }
  
  if(isPinned) {
    UIImage *const image = [UIImage imageWithContentsOfFile:
                            [[self URLForPinnedThumbnailImageOfBookIdentifier:book.identifier]
                             path]];
    if(image) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        handler(image);
      }];
      return;
    }
    
    // If the image didn't load, that just means it was an empty file used to mark that we still
    // need to download the pinned image.
    [[self.session
      dataTaskWithRequest:[NSURLRequest requestWithURL:book.imageThumbnailURL]
      completionHandler:^(NSData *const data,
                          __attribute__((unused)) NSURLResponse *response,
                          __attribute__((unused)) NSError *error) {
        @synchronized(self) {
          [[NSFileManager defaultManager]
           createFileAtPath:[[self URLForPinnedThumbnailImageOfBookIdentifier:book.identifier] path]
           contents:data
           attributes:nil];
        }
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          UIImage *const image = [UIImage imageWithData:data];
          if(image) {
            handler(image);
          } else {
            handler([NYPLTenPrintCoverView imageForBook:book]);
          }
        }];
      }]
     resume];
  } else {
    if(!book.imageThumbnailURL) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        handler([NYPLTenPrintCoverView imageForBook:book]);
      }];
      return;
    }
    [[self.session
      dataTaskWithRequest:[NSURLRequest requestWithURL:book.imageThumbnailURL]
      completionHandler:^(NSData *const data,
                          __attribute__((unused)) NSURLResponse *response,
                          __attribute__((unused)) NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          UIImage *const image = [UIImage imageWithData:data];
          if(image) {
            handler(image);
          } else {
            handler([NYPLTenPrintCoverView imageForBook:book]);
          }
        }];
      }]
     resume];
  }
}

- (void)thumbnailImagesForBooks:(NSSet *)books
                        handler:(void (^)(NSDictionary *bookIdentifiersToImagesAndNulls))handler
{
  if(!books) {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      handler(nil);
    }];
    return;
  }
  
  if(!books.count) {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      handler(@{});
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
      NYPLLOG_F(@"Missing thumbnail image URL for '%@'.", book.title);
      [lock lock];
      dictionary[book.identifier] = [NYPLTenPrintCoverView imageForBook:book];
      --remaining;
      if(!remaining) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          handler(dictionary);
        }];
      }
      [lock unlock];
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
            // All NSNull objects need to be converted to generated covers. We do this here rather
            // than earlier because it needs to happen on the main thread. The first step is to
            // get a map from book identifiers to books given our initial set.
            NSMutableDictionary *const identifiersToBooks =
              [NSMutableDictionary dictionaryWithCapacity:[books count]];
            for(NYPLBook *const book in books) {
              identifiersToBooks[book.identifier] = book;
            }
            // Now, we can fix up |dictionary| by replacing all nulls with generated covers.
            [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *const identifier,
                                                            id const imageOrNull,
                                                            __attribute__((unused)) BOOL *stop) {
              if([imageOrNull isKindOfClass:[NSNull class]]) {
                dictionary[identifier] =
                  [NYPLTenPrintCoverView imageForBook:identifiersToBooks[identifier]];
              }
            }];
            handler(dictionary);
          }];
        }
        [lock unlock];
      }]
     resume];
  }
}

- (UIImage *)cachedThumbnailImageForBook:(NYPLBook *const)book
{
  if(!book.imageThumbnailURL) {
    return nil;
  }
  
  return [UIImage imageWithData:
          [self.session.configuration.URLCache
           cachedResponseForRequest:[NSURLRequest requestWithURL:book.imageThumbnailURL]].data];
}

- (void)pinThumbnailImageForBook:(NYPLBook *const)book
{
  @synchronized(self) {
    // We create an empty file to mark that the thumbnail is pinned even if we do not manage to
    // finish fetching the image this application run.
    [[NSFileManager defaultManager]
     createFileAtPath:[[self URLForPinnedThumbnailImageOfBookIdentifier:book.identifier] path]
     contents:[NSData data]
     attributes:nil];
    
    [self.pinnedBookIdentifiers addObject:book];
  }
  
  [[self.session
    dataTaskWithRequest:[NSURLRequest requestWithURL:book.imageThumbnailURL]
    completionHandler:^(NSData *const data,
                        __attribute__((unused)) NSURLResponse *response,
                        __attribute__((unused)) NSError *error) {
      // FIXME: We should check if the image data is valid.
      if(!data) {
        NYPLLOG_F(@"Failed to pin thumbnail image for '%@'.", book.title);
        return;
      }
      
      @synchronized(self) {
        [[NSFileManager defaultManager]
         createFileAtPath:[[self URLForPinnedThumbnailImageOfBookIdentifier:book.identifier] path]
         contents:data
         attributes:nil];
      }
    }]
   resume];
}

- (void)removePinnedThumbnailImageForBookIdentifier:(NSString *const)bookIdentifier
{
  @synchronized(self) {
    [[NSFileManager defaultManager]
     removeItemAtURL:[self URLForPinnedThumbnailImageOfBookIdentifier:bookIdentifier]
     error:NULL];
    
    [self.pinnedBookIdentifiers removeObject:bookIdentifier];
  }
}

- (void)removeAllPinnedThumbnailImages
{
  @synchronized(self) {
    [[NSFileManager defaultManager]
     removeItemAtURL:[self pinnedThumbnailImageDirectoryURL]
     error:NULL];
    
    [self.pinnedBookIdentifiers removeAllObjects];
  }
}

@end
