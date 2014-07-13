#import "NYPLMyBooksRecord.h"

#import "NYPLMyBooksRegistry.h"

@interface NYPLMyBooksRegistry ()

@property (nonatomic) NSMutableDictionary *identifiersToRecords;

@end

static NSString *const RegistryFilename = @"registry.json";

static NSString *const BookMetadataKey = @"metadata";
static NSString *const StateKey = @"state";

@implementation NYPLMyBooksRegistry

+ (NYPLMyBooksRegistry *)sharedRegistry
{
  static dispatch_once_t predicate;
  static NYPLMyBooksRegistry *sharedRegistry = nil;
  
  dispatch_once(&predicate, ^{
    sharedRegistry = [[NYPLMyBooksRegistry alloc] init];
    if(!sharedRegistry) {
      NYPLLOG(@"Failed to create shared registry.");
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
  
  self.identifiersToRecords = [NSMutableDictionary dictionary];
  
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
    self.identifiersToRecords = [NSMutableDictionary dictionary];
    
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
      self.identifiersToRecords[key] = [NYPLMyBooksRecord recordWithDictionary:value];
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

- (void)addBook:(NYPLBook *const)book state:(NYPLMyBooksState)state
{
  if(!book) {
    @throw NSInvalidArgumentException;
  }
  
  @synchronized(self) {
    self.identifiersToRecords[book.identifier] = [[NYPLMyBooksRecord alloc]
                                                  initWithBook:book
                                                  state:state];
    [self broadcastChange];
  }
}

- (void)updateBook:(NYPLBook *const)book
{
  if(!book) {
    @throw NSInvalidArgumentException;
  }
  
  @synchronized(self) {
    NYPLMyBooksRecord *const record = self.identifiersToRecords[book.identifier];
    if(record) {
      self.identifiersToRecords[book.identifier] = [record recordWithBook:book];
      [self broadcastChange];
    }
  }
}

- (NYPLBook *)bookForIdentifier:(NSString *const)identifier
{
  @synchronized(self) {
    return ((NYPLMyBooksRecord *) self.identifiersToRecords[identifier]).book;
  }
}

- (void)removeBookForIdentifier:(NSString *const)identifier
{
  @synchronized(self) {
    [self.identifiersToRecords removeObjectForKey:identifier];
    [self broadcastChange];
  }
}

- (NSDictionary *)dictionaryRepresentation
{
  @synchronized(self) {
    NSMutableDictionary *const dictionary = [NSMutableDictionary dictionary];
    
    [self.identifiersToRecords
     enumerateKeysAndObjectsUsingBlock:^(NSString *const identifier,
                                         NYPLMyBooksRecord *const record,
                                         __attribute__((unused)) BOOL *stop) {
      dictionary[identifier] = [record dictionaryRepresentation];
    }];
    
    return dictionary;
  }
}

- (NSUInteger)count
{
  return self.identifiersToRecords.count;
}

- (NSArray *)allBooksSortedByBlock:(NSComparisonResult (^)(NYPLBook *a, NYPLBook *b))block
{
  NSMutableArray *const books = [NSMutableArray arrayWithCapacity:self.identifiersToRecords.count];
  
  [self.identifiersToRecords
   enumerateKeysAndObjectsUsingBlock:^(__attribute__((unused)) NSString *identifier,
                                       NYPLMyBooksRecord *const record,
                                       __attribute__((unused)) BOOL *stop) {
     [books addObject:record.book];
   }];
  
  return [books sortedArrayUsingComparator:block];
}

@end
