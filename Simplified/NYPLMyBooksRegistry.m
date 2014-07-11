#import "NYPLMyBooksRegistry.h"

@interface NYPLMyBooksRegistry ()

@property (nonatomic) NSMutableDictionary *identifiersToBooks;

@end

static NSString *const RegistryFilename = @"registry.json";

@implementation NYPLMyBooksRegistry

+ (NYPLMyBooksRegistry *)sharedRegistry
{
  static dispatch_once_t predicate;
  static NYPLMyBooksRegistry *sharedRegistry = nil;
  
  dispatch_once(&predicate, ^{
    sharedRegistry = [[NYPLMyBooksRegistry alloc] init];
    if(!sharedRegistry) {
      NYPLLOG(@"Failed to create shared content registry.");
    }
    
    [sharedRegistry load];
  });
  
  return sharedRegistry;
}

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.identifiersToBooks = [NSMutableDictionary dictionary];
  
  return self;
}

#pragma mark -

- (NSURL *)registryDirectory
{
  NSArray *const paths =
    NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
  
  assert([paths count] == 1);
  
  NSString *const path = paths[0];
  
  return [[[NSURL fileURLWithPath:path]
           URLByAppendingPathComponent:[[NSBundle mainBundle]
                                        objectForInfoDictionaryKey:@"CFBundleIdentifier"]]
          URLByAppendingPathComponent:@"registry"];
}

- (void)broadcastChange
{
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLBookRegistryDidChange
   object:self];
}

- (void)load
{
  @synchronized(self) {
    self.identifiersToBooks = [NSMutableDictionary dictionary];
    
    NSData *const savedData = [NSData dataWithContentsOfURL:
                               [[self registryDirectory]
                                URLByAppendingPathComponent:RegistryFilename]];
    
    if(!savedData) return;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wassign-enum"
    NSDictionary *const dictionary =
      [NSJSONSerialization
       JSONObjectWithData:savedData
       options:0
       error:NULL];
#pragma clang diagnostic pop
    
    if(!dictionary) {
      NYPLLOG(@"Failed to interpret saved registry data as JSON.");
      return;
    }
    
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id const key,
                                                    id const value,
                                                    __attribute__((unused)) BOOL *stop) {
      self.identifiersToBooks[key] = [[NYPLBook alloc] initWithDictionary:value];
    }];
    
    [self broadcastChange];
  }
}

- (void)save
{
  @synchronized(self) {
    if(![[NSFileManager defaultManager]
         createDirectoryAtURL:[self registryDirectory]
         withIntermediateDirectories:YES
         attributes:nil
         error:NULL]) {
      NYPLLOG(@"Failed to create registry directory.");
      return;
    }
    
    if(![[self registryDirectory] setResourceValue:@YES
                                            forKey:NSURLIsExcludedFromBackupKey
                                             error:NULL]) {
      NYPLLOG(@"Failed to exclude registry directory from backup.");
      return;
    }
    
    NSOutputStream *const stream =
      [NSOutputStream
       outputStreamWithURL:[[[self registryDirectory]
                             URLByAppendingPathComponent:RegistryFilename]
                            URLByAppendingPathExtension:@"temp"]
       append:NO];
    
    [stream open];
    
    // This try block is necessary to catch an (entirely undocumented) exception thrown by
    // NSJSONSerialization in the event that the provided stream isn't open for writing.
    @try {
      // This pragma is required because the NSJSONSerialization method below does not provide a
      // default NSJSONWritingOptions value.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wassign-enum"
      if(![NSJSONSerialization
           writeJSONObject:[self dictionaryRepresentation]
           toStream:stream
           options:0
           error:NULL]) {
#pragma clang diagnostic pop
        NYPLLOG(@"Failed to write book registry.");
        return;
      }
    } @catch(NSException *const exception) {
      NYPLLOG_F(@"Exception: %@: %@", [exception name], [exception reason]);
      return;
    } @finally {
      [stream close];
    }
    
    if(![[NSFileManager defaultManager]
         replaceItemAtURL:[[self registryDirectory] URLByAppendingPathComponent:RegistryFilename]
         withItemAtURL:[[[self registryDirectory]
                         URLByAppendingPathComponent:RegistryFilename]
                        URLByAppendingPathExtension:@"temp"]
         backupItemName:nil
         options:NSFileManagerItemReplacementUsingNewMetadataOnly
         resultingItemURL:NULL
         error:NULL]) {
      NYPLLOG(@"Failed to rename temporary registry file.");
      return;
    }    
  }
}

- (NYPLBook *)bookWithEntry:(NYPLOPDSEntry *const)entry
{
  if(!entry) {
    NYPLLOG(@"Failed to create book from nil entry.");
    return nil;
  }
  
  @synchronized(self) {
    NYPLBook *book = [self bookForIdentifier:entry.identifier];
    
    if(book) {
      book = [NYPLBook bookWithEntry:entry state:book.state];
      if(!book) {
        NYPLLOG(@"Failed to create book from entry with existing state.");
        return nil;
      }
      [self updateBook:book];
      return book;
    } else {
      book = [NYPLBook bookWithEntry:entry state:NYPLBookStateDefault];
      if(!book) {
        NYPLLOG(@"Failed to create book from entry.");
        return nil;
      }
      return book;
    }
  }
}


- (void)addBook:(NYPLBook *const)book
{
  if(!book) {
    @throw NSInvalidArgumentException;
  }
  
  @synchronized(self) {
    self.identifiersToBooks[book.identifier] = book;
    [self broadcastChange];
  }
}

- (void)updateBook:(NYPLBook *const)book
{
  if(!book) {
    @throw NSInvalidArgumentException;
  }
  
  @synchronized(self) {
    if(self.identifiersToBooks[book.identifier]) {
      self.identifiersToBooks[book.identifier] = book;
      [self broadcastChange];
    }
  }
}

- (NYPLBook *)bookForIdentifier:(NSString *const)identifier
{
  @synchronized(self) {
    return self.identifiersToBooks[identifier];
  }
}

- (void)removeBookForIdentifier:(NSString *const)identifier
{
  @synchronized(self) {
    [self.identifiersToBooks removeObjectForKey:identifier];
    [self broadcastChange];
  }
}

- (NSDictionary *)dictionaryRepresentation
{
  @synchronized(self) {
    NSMutableDictionary *const dictionary = [NSMutableDictionary dictionary];
    
    [self.identifiersToBooks
     enumerateKeysAndObjectsUsingBlock:^(NSString *const identifier,
                                         NYPLBook *const book,
                                         __attribute__((unused)) BOOL *stop) {
      dictionary[identifier] = [book dictionaryRepresentation];
    }];
    
    return dictionary;
  }
}

- (NSUInteger)count
{
  return self.identifiersToBooks.count;
}

- (NSArray *)allBooksSortedByBlock:(NSComparisonResult (^)(NYPLBook *a, NYPLBook *b))block
{
  return [[self.identifiersToBooks allValues] sortedArrayUsingComparator:block];
}

@end
