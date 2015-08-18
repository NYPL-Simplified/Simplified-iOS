#import "NYPLSettings.h"
#import "NSDate+NYPLDateAdditions.h"
#import "NYPLBook.h"

static NSString *const customMainFeedURLKey = @"NYPLSettingsCustomMainFeedURL";

static NSString *const renderingEngineKey = @"NYPLSettingsRenderingEngine";

static NSString *const userAcceptedEULAKey = @"NYPLSettingsUserAcceptedEULA";

static NSString *const eulaURLKey = @"NYPLSettingsEULAURL";

static NSString *const privacyPolicyURLKey = @"NYPLSettingsPrivacyPolicyURL";

static NSString *const preloadContentCompletedKey = @"NYPLSettingsPreloadContentCompleted";

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
      NYPLLOG(@"Failed to create shared settings.");
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

- (BOOL)preloadContentCompleted
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:preloadContentCompletedKey];
}

- (NSArray *) preloadedBookURLs {
  return [[NSBundle mainBundle] pathsForResourcesOfType:@"epub" inDirectory:@"PreloadedContent"];
}

- (NSString *) preloadedBookIDFromBundlePath: (NSString *) bookBundlePath {
  return [NSString stringWithFormat:@"Preloaded-%@", bookBundlePath.lastPathComponent];
}

- (NSArray *) preloadedBookIdentifiers {
  NSArray *bundlePathsToPreload = [[NYPLSettings sharedSettings] preloadedBookURLs];
  NSMutableArray *booksToPreloadIdentifiers = [[NSMutableArray alloc] init];
  
  for (NSString *bookBundlePath in bundlePathsToPreload) {
    NSString *bookID = [self preloadedBookIDFromBundlePath:bookBundlePath];
    [booksToPreloadIdentifiers addObject:bookID];
  }
  
  return booksToPreloadIdentifiers;
}

- (NSArray *) booksToPreload {
  NSArray *bundlePathsToPreload = [[NYPLSettings sharedSettings] preloadedBookURLs];
  NSMutableArray *booksToPreload = [[NSMutableArray alloc] init];
  
  for (NSString *bookBundlePath in bundlePathsToPreload) {
    
    NSURL *bookBundleURL = [NSURL fileURLWithPath:bookBundlePath];
    NSDictionary *acqDict = [[NSDictionary alloc] initWithObjectsAndKeys: @"", @"borrow",bookBundleURL.absoluteString, @"generic", @"", @"open-access", @"", @"sample", nil];
    NSArray *categoryArray = @[@"Preloaded"];
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
    
    NSArray *authorArray = @[bookAuthor];
    NSDate *today = [NSDate date];
    NSDictionary *bookDict = [[NSDictionary alloc] initWithObjectsAndKeys:acqDict, @"acquisition", authorArray, @"authors", categoryArray, @"categories", bookID , @"id", imagePath, @"image", imagePath, @"image-thumbnail", bookTitle, @"title", [today RFC3339String] , @"updated", nil];
    
    NYPLBook *book = [[NYPLBook alloc] initPreloadedWithDictionary:bookDict];
    if (book) {
      [booksToPreload addObject:book];
    }
  }
  
  return booksToPreload;
}

- (void) setUserAcceptedEULA:(BOOL)userAcceptedEULA {
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

- (void) setPreloadContentCompleted:(BOOL)preloadContentCompleted {
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
