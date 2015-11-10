#import "NYPLSettings.h"
#import "NYPLBookAcquisition.h"
#import "NSDate+NYPLDateAdditions.h"
#import "NYPLBook.h"
#import "NYPLBookRegistry.h"
#import "NYPLCardApplicationModel.h"

static NSString *const customMainFeedURLKey = @"NYPLSettingsCustomMainFeedURL";

static NSString *const renderingEngineKey = @"NYPLSettingsRenderingEngine";

static NSString *const userAcceptedEULAKey = @"NYPLSettingsUserAcceptedEULA";

static NSString *const eulaURLKey = @"NYPLSettingsEULAURL";

static NSString *const privacyPolicyURLKey = @"NYPLSettingsPrivacyPolicyURL";

static NSString *const acknowledgmentsURLKey = @"NYPLSettingsAcknowledgmentsURL";

static NSString *const preloadContentCompletedKey = @"NYPLSettingsPreloadContentCompleted";

static NSString *const currentCardApplicationSerializationKey = @"NYPLSettingsCurrentCardApplicationSerialized";

static NYPLSettingsRenderingEngine RenderingEngineFromString(NSString *const string)
{
  if(!string || [string isEqualToString:@"automatic"]) {
    return NYPLSettingsRenderingEngineAutomatic;
  }
  
  if([string isEqualToString:@"readium"]) {
    return NYPLSettingsRenderingEngineReadium;
  }
  
  @throw NSInvalidArgumentException;
}

static NSString *StringFromRenderingEngine(NYPLSettingsRenderingEngine const renderingEngine)
{
  switch(renderingEngine) {
    case NYPLSettingsRenderingEngineAutomatic:
      return @"automatic";
    case NYPLSettingsRenderingEngineReadium:
      return @"readium";
  }
}

@implementation NYPLSettings

+ (NYPLSettings *)sharedSettings
{
  static dispatch_once_t predicate;
  static NYPLSettings *sharedSettings;
  
  dispatch_once(&predicate, ^{
    sharedSettings = [[self alloc] init];
    if(!sharedSettings) {
      NYPLLOG(@"error", nil, nil, @"Failed to create shared settings.");
    }
  });
  
  return sharedSettings;
}

- (NSURL *)customMainFeedURL
{
  return [[NSUserDefaults standardUserDefaults] URLForKey:customMainFeedURLKey];
}

- (BOOL)userAcceptedEULA
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:userAcceptedEULAKey];
}

- (NSURL *)eulaURL
{
  return [[NSUserDefaults standardUserDefaults] URLForKey:eulaURLKey];
}

- (NSURL *)privacyPolicyURL
{
  return [[NSUserDefaults standardUserDefaults] URLForKey:privacyPolicyURLKey];
}

- (NSURL *) acknowledgmentsURL
{
  return [[NSUserDefaults standardUserDefaults] URLForKey:acknowledgmentsURLKey];
}

- (NYPLCardApplicationModel *)currentCardApplication
{
  NSData *currentCardApplicationSerialization = [[NSUserDefaults standardUserDefaults] objectForKey:currentCardApplicationSerializationKey];
  if (!currentCardApplicationSerialization)
    return nil;
  
  return [NSKeyedUnarchiver unarchiveObjectWithData:currentCardApplicationSerialization];
}

- (BOOL)preloadContentCompleted
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:preloadContentCompletedKey];
}

- (NSArray *)preloadedBookURLs
{
  return [[NSBundle mainBundle] pathsForResourcesOfType:@"epub" inDirectory:@"PreloadedContent"];
}

- (NSString *)preloadedBookIDFromBundlePath: (NSString *) bookBundlePath
{
  return [NSString stringWithFormat:@"Preloaded-%@", bookBundlePath.lastPathComponent];
}

- (NSArray *)preloadedBookIdentifiers
{
  NSArray *bundlePathsToPreload = [[NYPLSettings sharedSettings] preloadedBookURLs];
  NSMutableArray *booksToPreloadIdentifiers = [[NSMutableArray alloc] init];
  
  for (NSString *bookBundlePath in bundlePathsToPreload) {
    NSString *bookID = [self preloadedBookIDFromBundlePath:bookBundlePath];
    [booksToPreloadIdentifiers addObject:bookID];
  }
  
  return booksToPreloadIdentifiers;
}

- (NSArray *)booksToPreload
{
  NSArray *bundlePathsToPreload = [[NYPLSettings sharedSettings] preloadedBookURLs];
  NSMutableArray *booksToPreload = [[NSMutableArray alloc] init];
  
  for (NSString *bookBundlePath in bundlePathsToPreload) {
    
    NSURL *bookBundleURL = [NSURL fileURLWithPath:bookBundlePath];
    NSString *bookID = [self preloadedBookIDFromBundlePath:bookBundlePath];
    NSString *imagePath = [bookBundlePath stringByAppendingPathExtension:@"jpg"];
    
    NSArray *fileNameComponents = [[[bookBundlePath lastPathComponent] stringByDeletingPathExtension] componentsSeparatedByString:@"_-_"];
    NSString *bookTitle;
    NSString *bookAuthor;
    
    if (fileNameComponents.count == 2) {
      bookTitle = [[fileNameComponents firstObject] stringByAppendingString:@" (Preloaded)"];
      bookAuthor = [fileNameComponents lastObject];
    }
    else {
      bookTitle = [[bookBundlePath lastPathComponent] stringByDeletingPathExtension];
      bookAuthor = @"Preloaded Content";
    }
    
    NYPLBook *book = [[NYPLBook alloc] initWithAcquisition:[[NYPLBookAcquisition alloc] initWithBorrow:nil
                                                                                               generic:bookBundleURL
                                                                                            openAccess:nil
                                                                                                revoke:nil
                                                                                                sample:nil
                                                                                                report:nil]
                                             authorStrings:@[bookAuthor]
                                        availabilityStatus:NYPLBookAvailabilityStatusAvailable
                                           availableCopies:0
                                            availableUntil:nil
                                           categoryStrings:@[@"Preloaded"]
                                               distributor:@"Preloaded"
                                                identifier:bookID
                                                  imageURL:[NSURL fileURLWithPath:imagePath]
                                         imageThumbnailURL:[NSURL fileURLWithPath:imagePath]
                                                 published:nil
                                                 publisher:nil
                                                  subtitle:nil
                                                   summary:nil
                                                     title:bookTitle
                                                   updated:[NSDate date]];
    
    if (book) {
      [booksToPreload addObject:book];
    }
  }
  
  return booksToPreload;
}

- (NSArray *)booksToPreloadCurrentlyMissing
{
  
  NSArray *booksToCheck = [self booksToPreload];
  
  if (!booksToCheck || booksToCheck.count == 0 ) {
    return nil;
  }
  
  NSMutableArray *booksToRestore = [[NSMutableArray alloc] init];
  for (NYPLBook *book in booksToCheck) {
    
    NYPLBook *bookCheck = [[NYPLBookRegistry sharedRegistry] bookForIdentifier:book.identifier];
    if ( ![bookCheck.identifier isEqualToString:book.identifier] ) {
      [booksToRestore addObject:book];
    }
  }
  
  return booksToRestore;
}

- (NSArray *)booksToRestorePreloadedContentForIdentifiers:(NSArray *)identifiers
{
  NSArray *booksToCheck = [self booksToPreload];
  
  if (!identifiers || ![[identifiers class] isSubclassOfClass:[NSArray class]] || !booksToCheck || booksToCheck.count == 0 ) {
    return nil;
  }
  
  NSMutableArray *booksToRestore = [[NSMutableArray alloc] init];
  for (NYPLBook *book in booksToCheck) {
    if ( [identifiers containsObject:book.identifier] ) {
      [booksToRestore addObject:book];
    }
  }
  
  return booksToRestore;
}

- (void)setUserAcceptedEULA:(BOOL)userAcceptedEULA
{
  [[NSUserDefaults standardUserDefaults] setBool:userAcceptedEULA forKey:userAcceptedEULAKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setCustomMainFeedURL:(NSURL *const)customMainFeedURL
{
  if(!customMainFeedURL && !self.customMainFeedURL) return;
  if([customMainFeedURL isEqual:self.customMainFeedURL]) return;
  
  [[NSUserDefaults standardUserDefaults] setURL:customMainFeedURL forKey:customMainFeedURLKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLSettingsDidChangeNotification
   object:self];
}

- (void)setEulaURL:(NSURL *const)eulaURL
{
  if(!eulaURL) return;
  if([eulaURL isEqual:self.eulaURL]) return;
  
  [[NSUserDefaults standardUserDefaults] setURL:eulaURL forKey:eulaURLKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLSettingsDidChangeNotification
   object:self];
}

- (void)setPrivacyPolicyURL:(NSURL *)privacyPolicyURL
{
  if(!privacyPolicyURL) return;
  if([privacyPolicyURL isEqual:self.privacyPolicyURL]) return;
  
  [[NSUserDefaults standardUserDefaults] setURL:privacyPolicyURL forKey:privacyPolicyURLKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLSettingsDidChangeNotification
   object:self];
}

- (void)setAcknowledgmentsURL:(NSURL *)acknowledgmentsURL
{
  if(!acknowledgmentsURL) return;
  if([acknowledgmentsURL isEqual:self.acknowledgmentsURL]) return;
  
  [[NSUserDefaults standardUserDefaults] setURL:acknowledgmentsURL forKey:acknowledgmentsURLKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLSettingsDidChangeNotification
   object:self];
}

- (void)setCurrentCardApplication:(NYPLCardApplicationModel *)currentCardApplication
{
  if (!currentCardApplication) {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:currentCardApplicationSerializationKey];
    return;
  }
  
  NSData *cardAppData = [NSKeyedArchiver archivedDataWithRootObject:currentCardApplication];
  
  [[NSUserDefaults standardUserDefaults] setObject:cardAppData forKey:currentCardApplicationSerializationKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLSettingsDidChangeNotification
   object:self];
}

- (void)setPreloadContentCompleted:(BOOL)preloadContentCompleted
{
  [[NSUserDefaults standardUserDefaults] setBool:preloadContentCompleted forKey:preloadContentCompletedKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NYPLSettingsRenderingEngine)renderingEngine
{
  return RenderingEngineFromString([[NSUserDefaults standardUserDefaults]
                                    stringForKey:renderingEngineKey]);
}

- (void)setRenderingEngine:(NYPLSettingsRenderingEngine const)renderingEngine
{
  if(renderingEngine == self.renderingEngine) return;
  
  [[NSUserDefaults standardUserDefaults] setObject:StringFromRenderingEngine(renderingEngine)
                                            forKey:renderingEngineKey];
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLSettingsDidChangeNotification
   object:self];
}

@end
