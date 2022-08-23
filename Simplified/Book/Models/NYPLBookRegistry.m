#import "NYPLBookRegistry.h"

#import "NYPLBook.h"
#import "NYPLBookCoverRegistry.h"
#import "NYPLBookRegistryRecord.h"
#import "NYPLJSON.h"
#import "NYPLOPDS.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "SimplyE-Swift.h"

@interface NYPLBookRegistry ()

@property (nonatomic) NYPLBookCoverRegistry *coverRegistry;
@property (nonatomic) NSMutableDictionary *identifiersToRecords;
@property (atomic) BOOL shouldBroadcast;
@property (atomic) BOOL syncing;
@property (atomic) BOOL syncShouldCommit;
@property (nonatomic) BOOL delaySync;
@property (nonatomic, copy) void (^delayedSyncBlock)(void);
@property (nonatomic) NSMutableSet *processingIdentifiers;

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
      @throw NSMallocException;
    }
    
    [sharedRegistry justLoad];
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
  self.processingIdentifiers = [NSMutableSet set];
  self.shouldBroadcast = YES;
  return self;
}

#pragma mark -

- (NSURL *)registryDirectory
{
  NSURL *URL = [[NYPLBookContentMetadataFilesHelper currentAccountDirectory]
                URLByAppendingPathComponent:@"registry"];

  return URL;
}
- (NSURL *)registryDirectory:(NSString *)account
{
  NSURL *URL = [[NYPLBookContentMetadataFilesHelper directoryFor:account]
                URLByAppendingPathComponent:@"registry"];
  
  return URL;
}

- (NSArray<NSString *> *__nonnull)bookIdentifiersForAccount:(NSString * const)account
{
  NSURL *const url = [[NYPLBookContentMetadataFilesHelper directoryFor:account]
                      URLByAppendingPathComponent:@"registry/registry.json"];
  NSData *const data = [NSData dataWithContentsOfURL:url];
  if (!data) {
    return @[];
  }
  
  id const json = NYPLJSONObjectFromData(data);
  if (!json) @throw NSInternalInconsistencyException;
  
  NSDictionary *const dictionary = json;
  if (![dictionary isKindOfClass:[NSDictionary class]]) @throw NSInternalInconsistencyException;
  
  NSArray *const records = dictionary[@"records"];
  if (![records isKindOfClass:[NSArray class]]) @throw NSInternalInconsistencyException;
  
  NSMutableArray *const identifiers = [NSMutableArray arrayWithCapacity:records.count];
  for (NSDictionary *const record in records) {
    if (![record isKindOfClass:[NSDictionary class]]) @throw NSInternalInconsistencyException;
    NSDictionary *const metadata = record[@"metadata"];
    if (![metadata isKindOfClass:[NSDictionary class]]) @throw NSInternalInconsistencyException;
    NSString *const identifier = metadata[@"id"];
    if (![identifier isKindOfClass:[NSString class]]) @throw NSInternalInconsistencyException;
    [identifiers addObject:identifier];
  }
  
  return identifiers;
}

- (void)performSynchronizedWithoutBroadcasting:(void (^)(void))block
{
  @synchronized(self) {
    self.shouldBroadcast = NO;
    block();
    self.shouldBroadcast = YES;
  }
}

- (void)broadcastChange
{
  if (!self.shouldBroadcast) {
    return;
  }

  // We send the notification out on the next run through the run loop to avoid deadlocks that could
  // occur due to calling synchronized methods on this object in response to a broadcast that
  // originated from within a synchronized block.
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
      return;
    }

    [[NSNotificationCenter defaultCenter]
     postNotificationName:NSNotification.NYPLBookRegistryDidChange
     object:self];
  }];
}

- (void)broadcastProcessingChangeForIdentifier:(NSString *)identifier value:(BOOL)value
{
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:NSNotification.NYPLBookProcessingDidChange
     object:self
     userInfo:@{NYPLNotificationKeys.bookIDKey: identifier,
                NYPLNotificationKeys.bookProcessingValueKey: @(value)}];
  }];
}

- (void)justLoad
{
  NYPLLOG_F(@"Current Library Acct UUID: %@", [AccountsManager sharedInstance].currentAccount.uuid);
  [self loadWithoutBroadcastingForAccount:[AccountsManager sharedInstance].currentAccount.uuid];
  [self broadcastChange];
}

- (void)loadWithoutBroadcastingForAccount:(NSString *)account
{
  @synchronized(self) {
    self.identifiersToRecords = [NSMutableDictionary dictionary];
    
    NSData *const savedData = [NSData dataWithContentsOfURL:
                               [[self registryDirectory:account]
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
      // If record doesn't exist, proceed to next record
      if (!record) {
        continue;
      }
      // If a download was still in progress when we quit, it must now be failed.
      if(record.state == NYPLBookStateDownloading || record.state == NYPLBookStateSAMLStarted) {
        self.identifiersToRecords[record.book.identifier] =
        [record recordWithState:NYPLBookStateDownloadFailed];
      } else if (record.state == NYPLBookStateDownloadingUsable) {
        // If an audiobook background download was still in progress when we quit,
        // it will now be download successful and resume download when user open the book
        self.identifiersToRecords[record.book.identifier] =
        [record recordWithState:NYPLBookStateDownloadSuccessful];
      } else {
        self.identifiersToRecords[record.book.identifier] = record;
      }
    }
  }
}

- (void)save
{
  if ([AccountsManager.sharedInstance currentAccount] == nil) {
    return;
  }
  @synchronized(self) {
    NSError *error = nil;
    if(![[NSFileManager defaultManager]
         createDirectoryAtURL:[self registryDirectory]
         withIntermediateDirectories:YES
         attributes:nil
         error:&error]) {
      NYPLLOG(@"Failed to create registry directory.");
      return;
    }
    
    if(![[self registryDirectory] setResourceValue:@YES
                                            forKey:NSURLIsExcludedFromBackupKey
                                             error:&error]) {
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
           error:&error]) {
#pragma clang diagnostic pop
        NYPLLOG(@"Failed to write book registry.");
        return;
      }
    } @catch(NSException *const exception) {
      NYPLLOG([exception reason]);
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
         error:&error]) {
      NYPLLOG(@"Failed to rename temporary registry file.");
      return;
    }
  }
}

- (void)syncResettingCache:(BOOL)shouldResetCache
         completionHandler:(void (^)(NSDictionary *errorDict))handler
{
  [self syncResettingCache:shouldResetCache
         completionHandler:handler
    backgroundFetchHandler:nil];
}

- (void)syncResettingCache:(BOOL)shouldResetCache
         completionHandler:(void (^)(NSDictionary *errorDict))completion
    backgroundFetchHandler:(void (^)(UIBackgroundFetchResult))fetchHandler
{
  @synchronized(self) {
    [[NSNotificationCenter defaultCenter] postNotificationName:NSNotification.NYPLSyncBegan object:nil];

    const BOOL hasCredentials = NYPLUserAccount.sharedAccount.hasCredentials;
    if (self.syncing) {
      NYPLLOG(@"[syncWithCompletionHandler] Already syncing");
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if(fetchHandler) fetchHandler(UIBackgroundFetchResultNoData);
      }];
      return;
    } else if (!hasCredentials || !AccountsManager.shared.currentAccount.loansUrl) {
      NYPLLOG(@"[syncWithCompletionHandler] No valid credentials OR no Loans URL");
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if(completion) {
          NYPLProblemDocument *problemDoc = [NYPLProblemDocument forExpiredOrMissingCredentials:
                                             hasCredentials];
          if (hasCredentials) { // with no creds, it's not really an error
            [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeInvalidCredentials
                                      summary:@"Unable to sync loans: nil loansURL in library account"
                                     metadata:@{
                                       @"shouldResetCache": @(shouldResetCache),
                                       @"hasCredentials": @(hasCredentials),
                                       @"Synthesized Problem Doc": problemDoc.dictionaryValue
                                     }];
          }
          completion(problemDoc.dictionaryValue);
        }
        if(fetchHandler) fetchHandler(UIBackgroundFetchResultNoData);
        [[NSNotificationCenter defaultCenter] postNotificationName:NSNotification.NYPLSyncEnded object:nil];
      }];
      return;
    }

    self.syncing = YES;
    self.syncShouldCommit = YES;
    [self broadcastChange];
  } //@synchronized

  NYPLLOG(@"[syncWithCompletionHandler] Begin BookRegistry syncing...");
  [NYPLOPDSFeedFetcher fetchOPDSFeedWithUrl:[[[AccountsManager sharedInstance] currentAccount] loansUrl]
                            networkExecutor:[NYPLNetworkExecutor shared]
                           shouldResetCache:shouldResetCache
                                 completion:^(NYPLOPDSFeed * _Nullable feed, NSDictionary<NSString *,id> * _Nullable errorDict) {
    if(!feed) {
      NYPLLOG(@"Failed to obtain sync data.");
      self.syncing = NO;
      [self broadcastChange];
      [[NSOperationQueue mainQueue]
       addOperationWithBlock:^{
         if(completion) completion(errorDict);
         if(fetchHandler) fetchHandler(UIBackgroundFetchResultFailed);
         [[NSNotificationCenter defaultCenter] postNotificationName:NSNotification.NYPLSyncEnded object:nil];
       }];
      [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeApiCall
                                summary:@"Unable to fetch loans"
                               metadata:@{
                                 @"shouldResetCache": @(shouldResetCache),
                                 @"errorDict": errorDict ?: @"N/A"
                               }];
      return;
    }

    [NYPLErrorLogger setUserID:[[NYPLUserAccount sharedAccount] barcode]];
    
    if(!self.syncShouldCommit) {
      NYPLLOG(@"[syncWithCompletionHandler] Sync shouldn't commit");
      // A reset must have occurred.
      self.syncing = NO;
      [self broadcastChange];
      [[NSOperationQueue mainQueue]
       addOperationWithBlock:^{
         if(fetchHandler) fetchHandler(UIBackgroundFetchResultNoData);
      }];
      return;
    }
    
    void (^commitBlock)(void) = ^void() {
      [self performSynchronizedWithoutBroadcasting:^{

        if (feed.licensor) {
          [[NYPLUserAccount sharedAccount] setLicensor:feed.licensor];
          NYPLLOG_F(@"\nLicensor Token Updated: %@\nFor account: %@",feed.licensor[@"clientToken"],[NYPLUserAccount sharedAccount].userID);
        } else {
          NYPLLOG(@"A Licensor Token was not received or parsed from the OPDS feed.");
        }
        
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
            [self addBook:book location:nil state:NYPLBookStateDownloadNeeded fulfillmentId:nil readiumBookmarks:nil genericBookmarks:nil];
          }
        }
        for (NSString *identifier in identifiersToRemove) {
          NYPLBookRegistryRecord *record = [self.identifiersToRecords objectForKey:identifier];
          if (record && (record.state == NYPLBookStateDownloadSuccessful ||
                         record.state == NYPLBookStateUsed ||
                         record.state == NYPLBookStateDownloadingUsable)) {
            [[NYPLMyBooksDownloadCenter sharedDownloadCenter] deleteLocalContentForBookIdentifier:identifier];
          }
          [self removeBookForIdentifier:identifier];
        }
      }];
      self.syncing = NO;
      [self broadcastChange];
      [[NSOperationQueue mainQueue]
       addOperationWithBlock:^{
         [NYPLUserNotifications updateAppIconBadgeWithHeldBooks:[self heldBooks]];
         if(completion) completion(nil);
         if(fetchHandler) fetchHandler(UIBackgroundFetchResultNewData);
         [[NSNotificationCenter defaultCenter] postNotificationName:NSNotification.NYPLSyncEnded object:nil];
       }];
    };
    
    if (self.delaySync) {
      if (self.delayedSyncBlock) {
        NYPLLOG(@"[syncWithCompletionHandler] Delaying sync; block already exists!");
      } else {
        NYPLLOG(@"[syncWithCompletionHandler] Delaying sync");
      }
      self.delayedSyncBlock = commitBlock;
    } else {
      commitBlock();
    }
  }];
}

- (void)syncWithStandardAlertsOnCompletion
{
  [self syncResettingCache:YES completionHandler:^(NSDictionary *errorDict) {
    if (errorDict == nil) {
      [self save];
    } else {
      UIAlertController *alert = [NYPLAlertUtils alertWithTitle:@"SyncFailed"
                                                        message:@"We found a problem. Please check your connection or close and reopen the app to retry."];
      [NYPLAlertUtils presentFromViewControllerOrNilWithAlertController:alert viewController:nil animated:YES completion:nil];
    }
  }];
}

- (void)addBook:(NYPLBook *const)book
       location:(NYPLBookLocation *const)location
          state:(NSInteger)state
  fulfillmentId:(NSString *)fulfillmentId
readiumBookmarks:(NSArray<NYPLReadiumBookmark *> *)readiumBookmarks
genericBookmarks:(NSArray<NYPLBookLocation *> *)genericBookmarks
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
                                                  state:state
                                                  fulfillmentId:fulfillmentId
                                                  readiumBookmarks:readiumBookmarks
                                                  genericBookmarks:genericBookmarks];
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
      [NYPLUserNotifications compareAvailabilityWithCachedRecord:record andNewBook:book];
      self.identifiersToRecords[book.identifier] = [record recordWithBook:book];
      [self broadcastChange];
    }
  }
}

- (void)updateAndRemoveBook:(NYPLBook *)book
{
  if(!book) {
    return;
  }
  
  @synchronized(self) {
    NYPLBookRegistryRecord *const record = self.identifiersToRecords[book.identifier];
    if(record) {
      [self.coverRegistry removePinnedThumbnailImageForBookIdentifier:book.identifier];
      self.identifiersToRecords[book.identifier] = [[record recordWithBook:book] recordWithState:NYPLBookStateUnregistered];
      [self broadcastChange];
    }
  }
}

- (NYPLBook *)updatedBookMetadata:(NYPLBook *)book
{
  if(!book) {
    @throw NSInvalidArgumentException;
  }
  
  @synchronized(self) {
    NYPLBookRegistryRecord *const record = self.identifiersToRecords[book.identifier];
    if(record) {
      book = [record.book bookWithMetadataFromBook:book];
      NYPLBookRegistryRecord *const updatedRecord = [record recordWithBook:book];
      self.identifiersToRecords[book.identifier] = updatedRecord;
      NYPLBook *updatedBook = updatedRecord.book;
      [self broadcastChange];
      return updatedBook;
    }
    return nil;
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
      return;
    }
    
    self.identifiersToRecords[identifier] = [record recordWithState:state];
    
    [self broadcastChange];
  }
}

// TODO: Remove when migration to Swift completed
- (void)setStateWithCode:(NSInteger)stateCode forIdentifier:(nonnull NSString *)identifier
{
  [self setState:stateCode forIdentifier:identifier];
}

- (void)resetStateToDownloadNeededForIdentifier:(nonnull NSString *)identifier
{
  @synchronized(self) {
    NYPLBookRegistryRecord *const record = self.identifiersToRecords[identifier];
    if (!record) {
      return;
    }

    switch (record.state) {
      case NYPLBookStateDownloading:
      case NYPLBookStateDownloadFailed:
      case NYPLBookStateDownloadSuccessful:
      case NYPLBookStateDownloadingUsable:
      case NYPLBookStateUsed:
        self.identifiersToRecords[identifier] = [record recordWithState:NYPLBookStateDownloadNeeded];
        [self broadcastChange];
        break;
      case NYPLBookStateUnregistered:
      case NYPLBookStateDownloadNeeded:
      case NYPLBookStateHolding:
      case NYPLBookStateUnsupported:
      case NYPLBookStateSAMLStarted:
        break;
    }
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

- (NSInteger)stateRawValueForIdentifier:(nonnull NSString *)identifier {
  return [self stateForIdentifier:identifier];
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

- (void)setFulfillmentId:(NSString *)fulfillmentId forIdentifier:(NSString *)identifier
{
  @synchronized(self) {
    NYPLBookRegistryRecord *const record = self.identifiersToRecords[identifier];
    if(!record) {
      @throw NSInvalidArgumentException;
    }
    
    self.identifiersToRecords[identifier] = [record recordWithFulfillmentId:fulfillmentId];
    
    // This shouldn't be required, since nothing needs to display differently if the fulfillmentId changes
    // [self broadcastChange];
  }
}

- (NSString *)fulfillmentIdForIdentifier:(NSString *)identifier
{
  @synchronized(self) {
    NYPLBookRegistryRecord *const record = self.identifiersToRecords[identifier];
    return record.fulfillmentId;
  }
}

- (NSArray<NYPLReadiumBookmark *> *)readiumBookmarksForIdentifier:(NSString *)identifier
{
  @synchronized(self) {
    NYPLBookRegistryRecord *const record = self.identifiersToRecords[identifier];
    
    NSArray<NYPLReadiumBookmark *> *sortedArray = [record.readiumBookmarks sortedArrayUsingComparator:^NSComparisonResult(NYPLReadiumBookmark *obj1, NYPLReadiumBookmark *obj2) {
      if ([obj1 lessThan:obj2]) {
        return NSOrderedAscending;
      } else {
        return NSOrderedDescending;
      }
    }];
      
    return sortedArray ?: [NSArray array];
  }
}
  
-(void)addReadiumBookmark:(NYPLReadiumBookmark *)bookmark forIdentifier:(NSString *)identifier
{
  @synchronized(self) {
    
    NYPLBookRegistryRecord *const record = self.identifiersToRecords[identifier];
      
    NSMutableArray<NYPLReadiumBookmark *> *bookmarks = record.readiumBookmarks.mutableCopy;
    if (!bookmarks) {
      bookmarks = [NSMutableArray array];
    }
    [bookmarks addObject:bookmark];
    
    self.identifiersToRecords[identifier] = [record recordWithReadiumBookmarks:bookmarks];
    
    [[NYPLBookRegistry sharedRegistry] save];
  }
}
  
- (void)deleteReadiumBookmark:(NYPLReadiumBookmark *)bookmark forIdentifier:(NSString *)identifier
{
  @synchronized(self) {
      
    NYPLBookRegistryRecord *const record = self.identifiersToRecords[identifier];
      
    NSMutableArray<NYPLReadiumBookmark *> *bookmarks = record.readiumBookmarks.mutableCopy;
    if (!bookmarks) {
      return;
    }
    [bookmarks removeObject:bookmark];
    
    self.identifiersToRecords[identifier] = [record recordWithReadiumBookmarks:bookmarks];
    
    [[NYPLBookRegistry sharedRegistry] save];
  }
}

- (void)replaceBookmark:(NYPLReadiumBookmark *)oldBookmark with:(NYPLReadiumBookmark *)newBookmark forIdentifier:(NSString *)identifier
{
  @synchronized(self) {
    
    NYPLBookRegistryRecord *const record = self.identifiersToRecords[identifier];
    
    NSMutableArray<NYPLReadiumBookmark *> *bookmarks = record.readiumBookmarks.mutableCopy;
    if (!bookmarks) {
      return;
    }
    [bookmarks removeObject:oldBookmark];
    [bookmarks addObject:newBookmark];

    self.identifiersToRecords[identifier] = [record recordWithReadiumBookmarks:bookmarks];
    
    [[NYPLBookRegistry sharedRegistry] save];
  }
}

- (NSArray<NYPLBookLocation *> *)genericBookmarksForIdentifier:(NSString *)identifier
{
  @synchronized(self) {
    NYPLBookRegistryRecord *const record = self.identifiersToRecords[identifier];
    return record.genericBookmarks;
  }
}

- (void)addGenericBookmark:(NYPLBookLocation *)bookmark forIdentifier:(NSString *)identifier
{
  @synchronized(self) {

    NYPLBookRegistryRecord *const record = self.identifiersToRecords[identifier];

    NSMutableArray<NYPLBookLocation *> *bookmarks = record.genericBookmarks.mutableCopy;
    if (!bookmarks) {
      bookmarks = [NSMutableArray array];
    }
    [bookmarks addObject:bookmark];

    self.identifiersToRecords[identifier] = [record recordWithGenericBookmarks:bookmarks];

    [[NYPLBookRegistry sharedRegistry] save];
  }
}

- (void)deleteGenericBookmark:(NYPLBookLocation *)bookmark forIdentifier:(NSString *)identifier
{
  @synchronized(self) {

    NYPLBookRegistryRecord *const record = self.identifiersToRecords[identifier];

    NSMutableArray<NYPLBookLocation *> *bookmarks = record.genericBookmarks.mutableCopy;
    if (!bookmarks) {
      return;
    }
    NSArray<NYPLBookLocation *> *filteredArray =
    [bookmarks filteredArrayUsingPredicate:
     [NSPredicate predicateWithBlock:
      ^BOOL(NYPLBookLocation *object, __unused NSDictionary *bindings) {
        return [object.locationString isEqualToString:bookmark.locationString] == NO;
      }]];

    self.identifiersToRecords[identifier] = [record recordWithGenericBookmarks:filteredArray];

    [[NYPLBookRegistry sharedRegistry] save];
  }
}


- (void)setProcessing:(BOOL)processing forIdentifier:(NSString *)identifier
{
  // guard to avoid crash
  if (identifier == nil) {
    return;
  }

  @synchronized(self) {
    if(processing) {
      [self.processingIdentifiers addObject:identifier];
    } else {
      [self.processingIdentifiers removeObject:identifier];
    }
    [self broadcastProcessingChangeForIdentifier:identifier value:processing];
  }
}

- (BOOL)processingForIdentifier:(NSString *)identifier
{
  @synchronized(self) {
    return [self.processingIdentifiers containsObject:identifier];
  }
}

- (void)removeBookForIdentifier:(NSString *const)identifier
{
  @synchronized(self) {
    [self.coverRegistry removePinnedThumbnailImageForBookIdentifier:identifier];

    // somehow it is possible to get here with a nil book ID (see IOS-277) in
    // which case the book has already been removed from the registry, but we
    // still need to broadcast this removal event.
    if (identifier) {
      [self.identifiersToRecords removeObjectForKey:identifier];
    }
    [self broadcastChange];
  }
}

- (void)thumbnailImageForBook:(NYPLBook *const)book
                      handler:(void (^)(UIImage *image))handler
{
  [self.coverRegistry thumbnailImageForBook:book handler:handler];
}

- (void)coverImageForBook:(NYPLBook *const)book
                  handler:(void (^)(UIImage *image))handler
{
  [self.coverRegistry coverImageForBook:book handler:handler];
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

- (void)reset:(NSString *)account
{
  if ([[AccountsManager shared].currentAccount.uuid isEqualToString:account])
  {
    [self reset];
  }
  else
  {
    @synchronized(self) {
      [[NSFileManager defaultManager] removeItemAtURL:[self registryDirectory:account] error:NULL];
    }
  }
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
  return [self booksMatchingStates:[NYPLBookStateHelper allBookStates]];
}

- (NSArray *)heldBooks
{
  return [self booksMatchingStates:@[@(NYPLBookStateHolding)]];
}

- (NSArray *)myBooks
{
  return [self booksMatchingStates:@[@(NYPLBookStateDownloadNeeded),
                                     @(NYPLBookStateDownloading),
                                     @(NYPLBookStateDownloadingUsable),
                                     @(NYPLBookStateSAMLStarted),
                                     @(NYPLBookStateDownloadFailed),
                                     @(NYPLBookStateDownloadSuccessful),
                                     @(NYPLBookStateUsed)]];
}

- (NSArray *)booksMatchingStates:(NSArray * _Nonnull)states {
  @synchronized(self) {
    NSMutableArray *const books =
    [NSMutableArray arrayWithCapacity:self.identifiersToRecords.count];
    
    [self.identifiersToRecords
     enumerateKeysAndObjectsUsingBlock:^(__attribute__((unused)) NSString *identifier,
                                         NYPLBookRegistryRecord *const record,
                                         __attribute__((unused)) BOOL *stop) {
      if (record.state && [states containsObject:@(record.state)]) {
        [books addObject:record.book];
      }
    }];
    
    return books;
  }
}

- (void)delaySyncCommit
{
  self.delaySync = YES;
}

- (void)stopDelaySyncCommit
{
  self.delaySync = NO;
  if(self.delayedSyncBlock) {
    self.delayedSyncBlock();
    self.delayedSyncBlock = nil;
  }
}

- (void)performUsingAccount:(NSString * const)account block:(void (^const __nonnull)(void))block
{
  @synchronized (self) {
    if ([account isEqualToString:[AccountsManager sharedInstance].currentAccount.uuid]) {
      // Since we're already set to the account, do not reload data. Doing so would
      // be inefficient, but, more importantly, it would also wipe out download states.
      block();
    } else {
      // Since the function contract specifies that the registry will not be modified
      // by `block`, we have no need to copy `self.identifiersToRecords` here.
      NSMutableDictionary *const currentIdentifiersToRecords = self.identifiersToRecords;
      [self loadWithoutBroadcastingForAccount:account];
      block();
      self.identifiersToRecords = currentIdentifiersToRecords;
    }
  }
}

@end
