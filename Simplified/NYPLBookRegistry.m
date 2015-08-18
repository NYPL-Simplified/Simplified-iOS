#import "NYPLBook.h"
#import "NYPLBookCoverRegistry.h"
#import "NYPLBookRegistryRecord.h"
#import "NYPLConfiguration.h"
#import "NYPLJSON.h"
#import "NYPLOPDS.h"
#import "NYPLSettings.h"

#import "NYPLBookRegistry.h"

@interface NYPLBookRegistry ()

@property (nonatomic) NYPLBookCoverRegistry *coverRegistry;
@property (nonatomic) NSMutableDictionary *identifiersToRecords;
@property (atomic) BOOL shouldBroadcast;
@property (atomic) BOOL syncing;
@property (atomic) BOOL syncShouldCommit;

@end

static NSString *const RegistryFilename = @"registry.json";

static NSString *const RecordsKey = @"records";

@implementation NYPLBookRegistry

+ (NYPLBookRegistry *)sharedRegistry
{
  static dispatch_once_t predicate;
  static NYPLBookRegistry *sharedRegistry = nil;
  
  dispatch_once(&predicate, ^{
    // Cast allows access to unavailable |init| method.
    sharedRegistry = [[self alloc] init];
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
  
  self.coverRegistry = [[NYPLBookCoverRegistry alloc] init];
  self.identifiersToRecords = [NSMutableDictionary dictionary];
  self.shouldBroadcast = YES;
  
  void (^handlerBlock)(BOOL success)= ^(BOOL success){
    if(success) {
      [[NYPLBookRegistry sharedRegistry] save];
    } else {
    }};
  
  [self performSelector:@selector(syncWithCompletionHandler:) withObject:handlerBlock afterDelay:3.0];
  
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

- (void)performSynchronizedWithoutBroadcasting:(void (^)())block
{
  @synchronized(self) {
    self.shouldBroadcast = NO;
    block();
    self.shouldBroadcast = YES;
  }
}

- (void)broadcastChange
{
  if(!self.shouldBroadcast) {
    return;
  }
  
  // We send the notification out on the next run through the run loop to avoid deadlocks that could
  // occur due to calling synchronized methods on this object in response to a broadcast that
  // originated from within a synchronized block.
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:NYPLBookRegistryDidChangeNotification
     object:self];
  }];
}

- (void)load
{
  @synchronized(self) {
    self.identifiersToRecords = [NSMutableDictionary dictionary];
    
    NSData *const savedData = [NSData dataWithContentsOfURL:
                               [[self registryDirectory]
                                URLByAppendingPathComponent:RegistryFilename]];
    
    if(!savedData) return;
    
    NSDictionary *const dictionary = NYPLJSONObjectFromData(savedData);
    
    if(!dictionary) {
      NYPLLOG(@"Failed to interpret saved registry data as JSON.");
      return;
    }
    
    for(NSDictionary *const recordDictionary in dictionary[RecordsKey]) {
      NYPLBookRegistryRecord *const record = [[NYPLBookRegistryRecord alloc]
                                              initWithDictionary:recordDictionary];
      // If a download was still in progress when we quit, it must now be failed.
      if(record.state == NYPLBookStateDownloading) {
        self.identifiersToRecords[record.book.identifier] =
        [record recordWithState:NYPLBookStateDownloadFailed];
      } else {
        self.identifiersToRecords[record.book.identifier] = record;
      }
    }
    
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

- (void)syncWithCompletionHandler:(void (^)(BOOL success))handler
{
  @synchronized(self) {
    if(self.syncing) {
      return;
    } else {
      self.syncing = YES;
      self.syncShouldCommit = YES;
      [self broadcastChange];
    }
  }
  
  [NYPLOPDSFeed
   withURL:[NYPLConfiguration loanURL]
   completionHandler:^(NYPLOPDSFeed *const feed) {
     if(!feed) {
       NYPLLOG(@"Failed to obtain sync data.");
       self.syncing = NO;
       [self broadcastChange];
       [[NSOperationQueue mainQueue]
        addOperationWithBlock:^{
          if(handler) handler(NO);
        }];
       return;
     }
     
     if(!self.syncShouldCommit) {
       // A reset must have occurred.
       self.syncing = NO;
       [self broadcastChange];
       return;
     }
     
     [self performSynchronizedWithoutBroadcasting:^{
       NSMutableSet *identifiersToRemove = [NSMutableSet setWithArray:self.identifiersToRecords.allKeys];
       for(NYPLOPDSEntry *const entry in feed.entries) {
         NYPLBook *const book = [NYPLBook bookWithEntry:entry];
         if(!book) {
           NYPLLOG_F(@"Failed to create book for entry '%@'.", entry.identifier);
           continue;
         }
         [identifiersToRemove removeObject:book.identifier];
         NYPLBook *const existingBook = [self bookForIdentifier:book.identifier];
         if(existingBook) {
           [self updateBook:book];
         } else {
           [self addBook:book location:nil state:NYPLBookStateDownloadNeeded];
         }
       }
       for (NSString *identifier in identifiersToRemove) {
         if (![[[NYPLSettings sharedSettings] preloadedBookIdentifiers] containsObject:identifier]) {
           [self removeBookForIdentifier:identifier];
         }
       }
     }];
     self.syncing = NO;
     [self broadcastChange];
     [[NSOperationQueue mainQueue]
      addOperationWithBlock:^{
        if(handler) handler(YES);
      }];
   }];
}

- (void)syncWithStandardAlertsOnCompletion
{
  [self syncWithCompletionHandler:^(BOOL success) {
    if(success) {
      [[[UIAlertView alloc]
        initWithTitle:NSLocalizedString(@"SyncComplete", nil)
        message:NSLocalizedString(@"YourBooksWereSyncedSuccessfully", nil)
        delegate:nil
        cancelButtonTitle:nil
        otherButtonTitles:@"OK", nil]
       show];
      
      [[NYPLBookRegistry sharedRegistry] save];
    } else {
      [[[UIAlertView alloc]
        initWithTitle:NSLocalizedString(@"SyncFailed", nil)
        message:NSLocalizedString(@"CheckConnection", nil)
        delegate:nil
        cancelButtonTitle:nil
        otherButtonTitles:@"OK", nil]
       show];
    }
  }];
}

- (void)addBook:(NYPLBook *const)book
       location:(NYPLBookLocation *const)location
          state:(NYPLBookState)state
{
  if(!book) {
    @throw NSInvalidArgumentException;
  }
  
  if(state == NYPLBookStateUnregistered) {
    @throw NSInvalidArgumentException;
  }
  
  @synchronized(self) {
    [self.coverRegistry pinThumbnailImageForBook:book];
    self.identifiersToRecords[book.identifier] = [[NYPLBookRegistryRecord alloc]
                                                  initWithBook:book
                                                  location:location
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
    NYPLBookRegistryRecord *const record = self.identifiersToRecords[book.identifier];
    if(record) {
      self.identifiersToRecords[book.identifier] = [record recordWithBook:book];
      [self broadcastChange];
    }
  }
}

- (NYPLBook *)bookForIdentifier:(NSString *const)identifier
{
  @synchronized(self) {
    return ((NYPLBookRegistryRecord *) self.identifiersToRecords[identifier]).book;
  }
}

- (void)setState:(NYPLBookState)state forIdentifier:(NSString *const)identifier
{
  @synchronized(self) {
    NYPLBookRegistryRecord *const record = self.identifiersToRecords[identifier];
    if(!record) {
      @throw NSInvalidArgumentException;
    }
    
    self.identifiersToRecords[identifier] = [record recordWithState:state];
    
    [self broadcastChange];
  }
}

- (NYPLBookState)stateForIdentifier:(NSString *const)identifier
{
  @synchronized(self) {
    NYPLBookRegistryRecord *const record = self.identifiersToRecords[identifier];
    if(record) {
      return record.state;
    } else {
      return NYPLBookStateUnregistered;
    }
  }
}

- (void)setLocation:(NYPLBookLocation *const)location forIdentifier:(NSString *const)identifier
{
  @synchronized(self) {
    NYPLBookRegistryRecord *const record = self.identifiersToRecords[identifier];
    if(!record) {
      @throw NSInvalidArgumentException;
    }
    
    self.identifiersToRecords[identifier] = [record recordWithLocation:location];
    
    [self broadcastChange];
  }
}

- (NYPLBookLocation *)locationForIdentifier:(NSString *const)identifier
{
  @synchronized(self) {
    NYPLBookRegistryRecord *const record = self.identifiersToRecords[identifier];
    return record.location;
  }
}

- (void)removeBookForIdentifier:(NSString *const)identifier
{
  @synchronized(self) {
    [self.coverRegistry removePinnedThumbnailImageForBookIdentifier:identifier];
    [self.identifiersToRecords removeObjectForKey:identifier];
    [self broadcastChange];
  }
}

- (void)thumbnailImageForBook:(NYPLBook *const)book
                      handler:(void (^)(UIImage *image))handler
{
  [self.coverRegistry thumbnailImageForBook:book handler:handler];
}

- (void)thumbnailImagesForBooks:(NSSet *const)books
                        handler:(void (^)(NSDictionary *bookIdentifiersToImages))handler
{
  [self.coverRegistry thumbnailImagesForBooks:books handler:handler];
}

- (UIImage *)cachedThumbnailImageForBook:(NYPLBook *const)book
{
  return [self.coverRegistry cachedThumbnailImageForBook:book];
}

- (void)reset
{
  @synchronized(self) {
    self.syncShouldCommit = NO;
    [self.coverRegistry removeAllPinnedThumbnailImages];
    [self.identifiersToRecords removeAllObjects];
    [[NSFileManager defaultManager] removeItemAtURL:[self registryDirectory] error:NULL];
  }
  
  [self broadcastChange];
}

- (NSDictionary *)dictionaryRepresentation
{
  NSMutableArray *const records =
    [NSMutableArray arrayWithCapacity:self.identifiersToRecords.count];
  
  for(NYPLBookRegistryRecord *const record in [self.identifiersToRecords allValues]) {
    [records addObject:[record dictionaryRepresentation]];
  }
  
  return @{RecordsKey: records};
}

- (NSUInteger)count
{
  @synchronized(self) {
    return self.identifiersToRecords.count;
  }
}

- (NSArray *)allBooks
{
  return [self booksMatchingStateMask:~0];
}

- (NSArray *)heldBooks
{
  return [self booksMatchingStateMask:NYPLBookStateHolding];
}

- (NSArray *)myBooks
{
  return [self booksMatchingStateMask:~NYPLBookStateHolding];
}

- (NSArray *)booksMatchingStateMask:(NSUInteger)mask
{
  @synchronized(self) {
    NSMutableArray *const books =
    [NSMutableArray arrayWithCapacity:self.identifiersToRecords.count];
    
    [self.identifiersToRecords
     enumerateKeysAndObjectsUsingBlock:^(__attribute__((unused)) NSString *identifier,
                                         NYPLBookRegistryRecord *const record,
                                         __attribute__((unused)) BOOL *stop) {
       if (record.state & mask) {
         [books addObject:record.book];
       }
     }];
    
    return books;
  }
}

@end
