#import "NYPLSettings.h"
#import "NSDate+NYPLDateAdditions.h"
#import "NYPLBook.h"
#import "NYPLBookRegistry.h"
#import "NYPLConfiguration.h"
#import "SimplyE-Swift.h"

const NSInteger Version = 1;

NSString *const NYPLSettingsDidChangeNotification = @"NYPLSettingsDidChangeNotification";
NSString *const NYPLCurrentAccountDidChangeNotification = @"NYPLCurrentAccountDidChangeNotification";
NSString *const NYPLSyncBeganNotification = @"NYPLSyncBeganNotification";
NSString *const NYPLSyncEndedNotification = @"NYPLSyncEndedNotification";

static NSString *const customMainFeedURLKey = @"NYPLSettingsCustomMainFeedURL";

static NSString *const accountMainFeedURLKey = @"NYPLSettingsAccountMainFeedURL";

static NSString *const renderingEngineKey = @"NYPLSettingsRenderingEngine";

static NSString *const legacyUserAcceptedEULAKey = @"NYPLSettingsUserAcceptedEULA";

//static NSString *const settingsSynchronizeAnnotationsKey = @"NYPLSettingsSynchronizeAnnotationsKey";

static NSString *const userPresentedAgeCheckKey = @"NYPLUserPresentedAgeCheckKey";

static NSString *const userSeenFirstTimeSyncMessageKey = @"userSeenFirstTimeSyncMessageKey";

static NSString *const currentCardApplicationSerializationKey = @"NYPLSettingsCurrentCardApplicationSerialized";

static NSString *const settingsLibraryAccountsKey = @"NYPLSettingsLibraryAccountsKey";

static NSString *const settingsOfflineQueueKey = @"NYPLSettingsOfflineQueueKey";

static NSString *const settingsAnnotationsOfflineQueueKey = @"NYPLSettingsAnnotationsOfflineQueueKey";

static NSString *const versionKey = @"NYPLSettingsVersionKey";


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

- (NSURL *)accountMainFeedURL
{
  return [[NSUserDefaults standardUserDefaults] URLForKey:accountMainFeedURLKey];
}

- (BOOL) userHasSeenWelcomeScreen
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:userHasSeenWelcomeScreenKey];
}

- (BOOL) userPresentedAgeCheck
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:userPresentedAgeCheckKey];
}

- (BOOL) userHasSeenFirstTimeSyncMessage
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:userSeenFirstTimeSyncMessageKey];
}

// FIXME: This should be in `AccountsManager`, not `NYPLSettings`.
- (NSArray *) settingsAccountsList
{
  NSArray *libraryAccounts = [[NSUserDefaults standardUserDefaults] arrayForKey:settingsLibraryAccountsKey];
  // If user has not selected any accounts yet, return the "currentAccount"
  if (!libraryAccounts) {
    NSString *currentLibrary = [AccountsManager shared].currentAccount.uuid;
    [self setSettingsAccountsList:@[currentLibrary, [AccountsManager NYPLAccountUUIDs][2]]];
    return [self settingsAccountsList];
  } else {
    return libraryAccounts;
  }
}

- (NYPLCardApplicationModel *)currentCardApplication
{
  NSData *currentCardApplicationSerialization = [[NSUserDefaults standardUserDefaults] objectForKey:currentCardApplicationSerializationKey];
  if (!currentCardApplicationSerialization)
    return nil;
  
  return [NSKeyedUnarchiver unarchiveObjectWithData:currentCardApplicationSerialization];
}

- (void)setUserHasSeenWelcomeScreen:(BOOL)userPresentedScreen
{
  [[NSUserDefaults standardUserDefaults] setBool:userPresentedScreen forKey:userHasSeenWelcomeScreenKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setUserPresentedAgeCheck:(BOOL)userPresentedAgeCheck
{
  [[NSUserDefaults standardUserDefaults] setBool:userPresentedAgeCheck forKey:userPresentedAgeCheckKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setUserHasSeenFirstTimeSyncMessage:(BOOL)seenSyncMesssage
{
  [[NSUserDefaults standardUserDefaults] setBool:seenSyncMesssage forKey:userSeenFirstTimeSyncMessageKey];
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
- (void)setAccountMainFeedURL:(NSURL *const)accountMainFeedURL
{
  if(!accountMainFeedURL && !self.accountMainFeedURL) return;
  if([accountMainFeedURL isEqual:self.accountMainFeedURL]) return;
  
  [[NSUserDefaults standardUserDefaults] setURL:accountMainFeedURL forKey:accountMainFeedURLKey];
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

- (void)setSettingsAccountsList:(NSArray *)accounts
{
  [[NSUserDefaults standardUserDefaults] setObject:accounts forKey:settingsLibraryAccountsKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NYPLSettingsRenderingEngine)renderingEngine
{
  return RenderingEngineFromString([[NSUserDefaults standardUserDefaults]
                                    stringForKey:renderingEngineKey]);
}

- (void)setRenderingEngine:(NYPLSettingsRenderingEngine const)renderingEngine
{
  if (renderingEngine == self.renderingEngine) return;
  
  [[NSUserDefaults standardUserDefaults] setObject:StringFromRenderingEngine(renderingEngine)
                                            forKey:renderingEngineKey];
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLSettingsDidChangeNotification
   object:self];
}

- (void)migrate
{
  NSInteger version = [[NSUserDefaults standardUserDefaults] integerForKey:versionKey];
  while (version < Version) {
    switch (version) {
      case 0: {
        NSArray *libraryAccounts = [[NSUserDefaults standardUserDefaults] arrayForKey:settingsLibraryAccountsKey];
        if (!libraryAccounts) {
          break;
        }
        
        // Load Accounts.json
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Accounts" ofType:@"json"];
        if (filePath) {
          NSData *data = [NSData dataWithContentsOfFile:filePath];
          __autoreleasing NSError* error = nil;
          NSArray *accountList = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
          NSMutableDictionary *idToUuidMap = [[NSMutableDictionary alloc] init];
          for (NSDictionary *account in accountList) {
            id numericVal = [account objectForKey:@"id_numeric"];
            id uuidVal = [account objectForKey:@"id_uuid"];
            if (numericVal && uuidVal) {
              [idToUuidMap setObject:uuidVal forKey:[numericVal stringValue]];
            }
          }
          
          // Migrate accounts
          NSMutableArray* newLibraryAccountsList = [NSMutableArray arrayWithCapacity:libraryAccounts.count];
          for (id account in libraryAccounts) {
            id uuidObj = [idToUuidMap objectForKey:[account stringValue]];
            if (uuidObj) {
              [newLibraryAccountsList addObject:uuidObj];
            }
          }
          [[NSUserDefaults standardUserDefaults] setObject:newLibraryAccountsList forKey:settingsLibraryAccountsKey];
        } else {
          [[NSUserDefaults standardUserDefaults] removeObjectForKey:settingsLibraryAccountsKey];
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
      }
        break;
      default:
        break;
    }
    version += 1;
  }
  [[NSUserDefaults standardUserDefaults] setInteger:Version forKey:versionKey];
}

@end
