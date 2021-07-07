#import "NSString+NYPLStringAdditions.h"
#import "NYPLBook.h"
#import "NYPLBookRegistry.h"
#import "NYPLNull.h"
#import "NYPLTenPrintCoverView+NYPLImageAdditions.h"

#import "NYPLBookCoverRegistry.h"
#import "SimplyE-Swift.h"

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
  configuration.timeoutIntervalForRequest = 15.0;
  configuration.timeoutIntervalForResource = 30.0;
  configuration.URLCache.diskCapacity = 1024 * 1024 * diskCacheInMegabytes;
  configuration.URLCache.memoryCapacity = 1024 * 1024 * memoryCacheInMegabytes;
  configuration.URLCredentialStorage = nil;
  
  self.session = [NSURLSession sessionWithConfiguration:configuration];
  
  return self;
}

#pragma mark -

- (NSURL *)pinnedThumbnailImageDirectoryURL
{
  NSURL *URL = [[NYPLBookContentMetadataFilesHelper currentAccountDirectory] URLByAppendingPathComponent:@"pinned-thumbnail-images"];

  if (URL != nil) {
    @synchronized(self) {
      NSError *error = nil;
      if(![[NSFileManager defaultManager]
           createDirectoryAtURL:URL
           withIntermediateDirectories:YES
           attributes:nil
           error:&error]) {
        NYPLLOG(@"Failed to create directory.");
        return nil;
      }
    }
  } else {
    NYPLLOG(@"[pinnedThumbnailImageDirectoryURL] nil directory");
  }
  
  return URL;
}

- (nullable NSURL *)URLForPinnedThumbnailImageOfBookIdentifier:(NSString *const)bookIdentifier
{
  NSString *encryptedBookID = [bookIdentifier SHA256];
  if (encryptedBookID) {
    return [[self pinnedThumbnailImageDirectoryURL]
            URLByAppendingPathComponent:encryptedBookID];
  }
  return nil;
}

- (void)coverImageForBook:(NYPLBook *)book handler:(void (^)(UIImage *image))handler
{

  //Thumbnail first as placeholder
  [self thumbnailImageForBook:book handler:handler];

  [[self.session
    dataTaskWithRequest:[NSURLRequest requestWithURL:book.imageURL]
    completionHandler:^(NSData *const data,
                        __attribute__((unused)) NSURLResponse *response,
                        __attribute__((unused)) NSError *error) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        UIImage *const image = [UIImage imageWithData:data];
        if(image) {
          handler(image);
        } else {
          [self thumbnailImageForBook:book handler:handler];
        }
      }];
    }]
   resume];
}

- (void)thumbnailImageForBook:(NYPLBook *)book handler:(void (^)(UIImage *image))handler
{
  if(!(book && handler)) {
    @throw NSInvalidArgumentException;
  }
  
  BOOL const isPinned = !![[NYPLBookRegistry sharedRegistry] bookForIdentifier:book.identifier];
  NSString *filePath =  [[self URLForPinnedThumbnailImageOfBookIdentifier:book.identifier] path];
  
  if(isPinned) {
    if (filePath) {
      UIImage *const image = [UIImage imageWithContentsOfFile:filePath];
      if(image) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          handler(image);
        }];
        return;
      }
    }
    
    // If the image didn't load, that means we still need to download the pinned image.
    [self getBookCoverImageWithURL:book.imageThumbnailURL
                  createFileAtPath:filePath
                           handler:handler
                           forBook:book];
  } else {
    if(!book.imageThumbnailURL) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        handler([NYPLTenPrintCoverView imageForBook:book]);
      }];
      return;
    }
      
    [self getBookCoverImageWithURL:book.imageThumbnailURL
                  createFileAtPath:nil
                           handler:handler
                           forBook:book];
  }
}

- (void) getBookCoverImageWithURL:(nonnull NSURL *)imageURL
                     createFileAtPath:(nullable NSString *)path
                              handler:(void (^)(UIImage *image))handler
                              forBook:(nonnull NYPLBook *)book {
  [[self.session
    dataTaskWithRequest:[NSURLRequest requestWithURL:imageURL]
    completionHandler:^(NSData *const data,
                        __attribute__((unused)) NSURLResponse *response,
                        __attribute__((unused)) NSError *error) {
      
      if (path) {
        @synchronized(self) {
          [[NSFileManager defaultManager]
           createFileAtPath:path
           contents:data
           attributes:nil];
        }
      }
        
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        UIImage *const image = [UIImage imageWithData:data];
        if (image) {
          handler(image);
        } else {
          handler([NYPLTenPrintCoverView imageForBook:book]);
        }
      }];
  }]
   resume];
}

- (void)thumbnailImagesForBooks:(NSSet *)books
                        handler:(void (^)(NSDictionary *bookIdentifiersToImagesAndNulls))handler
{
  if(!(books && handler)) {
    @throw NSInvalidArgumentException;
  }
  
  if(!books.count) {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      handler(@{});
    }];
    return;
  }
  
  for(id const object in books) {
    if(![object isKindOfClass:[NYPLBook class]]) {
      @throw NSInvalidArgumentException;
    }
  }
  
  NSLock *const lock = [[NSLock alloc] init];
  NSMutableDictionary *const dictionary = [NSMutableDictionary dictionary];
  __block NSUInteger remaining = books.count;
  
  for(NYPLBook *const book in books) {
    if(!book.imageThumbnailURL) {
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
  NSString *path = [[self URLForPinnedThumbnailImageOfBookIdentifier:book.identifier] path];
  if (!path) {
    return;
  }
  
  @synchronized(self) {
    // We create an empty file to mark that the thumbnail is pinned even if we do not manage to
    // finish fetching the image this application run.
    [[NSFileManager defaultManager]
     createFileAtPath:path
     contents:[NSData data]
     attributes:nil];
  }
  
  [[self.session
    dataTaskWithRequest:[NSURLRequest requestWithURL:book.imageThumbnailURL]
    completionHandler:^(NSData *const data,
                        __attribute__((unused)) NSURLResponse *response,
                        __attribute__((unused)) NSError *error) {
      if(!data || ![UIImage imageWithData:data]) {
        return;
      }
      
      if (path) {
        @synchronized(self) {
          [[NSFileManager defaultManager]
           createFileAtPath:path
           contents:data
           attributes:nil];
        }
      }
    }]
   resume];
}

- (void)removePinnedThumbnailImageForBookIdentifier:(NSString *const)bookIdentifier
{
  NSURL *url = [self URLForPinnedThumbnailImageOfBookIdentifier:bookIdentifier];
  if (url) {
    @synchronized(self) {
      [[NSFileManager defaultManager]
       removeItemAtURL:url
       error:NULL];
    }
  }
}

- (void)removeAllPinnedThumbnailImages
{
  @synchronized(self) {
    [[NSFileManager defaultManager]
     removeItemAtURL:[self pinnedThumbnailImageDirectoryURL]
     error:NULL];
  }
}

@end
