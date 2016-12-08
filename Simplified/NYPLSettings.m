#import "NYPLSettings.h"
#import "NYPLBookAcquisition.h"
#import "NSDate+NYPLDateAdditions.h"
#import "NYPLBook.h"
#import "NYPLBookRegistry.h"
#import "NYPLConfiguration.h"
#import "SimplyE-Swift.h"

static NSString *const currentAccountIdentifierKey = @"NYPLCurrentAccountIdentifier";

static NSString *const customMainFeedURLKey = @"NYPLSettingsCustomMainFeedURL";

static NSString *const accountMainFeedURLKey = @"NYPLSettingsAccountMainFeedURL";

static NSString *const renderingEngineKey = @"NYPLSettingsRenderingEngine";

static NSString *const userPresentedWelcomeScreenKey = @"NYPLUserPresentedWelcomeScreenKey";

static NSString *const currentCardApplicationSerializationKey = @"NYPLSettingsCurrentCardApplicationSerialized";

static NSString *const settingsLibraryAccountsKey = @"NYPLSettingsLibraryAccountsKey";


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
- (Account*)currentAccount
{
  return [[AccountsManager sharedInstance] account:[[NYPLSettings sharedSettings] currentAccountIdentifier]];
}

- (NSInteger)currentAccountIdentifier
{
  return [[NSUserDefaults standardUserDefaults] integerForKey:currentAccountIdentifierKey];
}
- (NSURL *)customMainFeedURL
{
  return [[NSUserDefaults standardUserDefaults] URLForKey:customMainFeedURLKey];
}

- (NSURL *)accountMainFeedURL
{
  return [[NSUserDefaults standardUserDefaults] URLForKey:accountMainFeedURLKey];
}

- (BOOL) userPresentedWelcomeScreen
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:userPresentedWelcomeScreenKey];
}

- (NSArray *) settingsAccountsList
{
  NSArray *libraryAccounts = [[NSUserDefaults standardUserDefaults] arrayForKey:settingsLibraryAccountsKey];
  // If user has not selected any accounts yet, return the "currentAccount"
  if (!libraryAccounts) {
    NSInteger currentLibrary = [self currentAccountIdentifier];
    [self setSettingsAccountsList:@[@(currentLibrary), @2]];
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
- (void)setCurrentAccountIdentifier:(NSInteger)account
{
  [[NSUserDefaults standardUserDefaults] setInteger:account forKey:currentAccountIdentifierKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLCurrentAccountDidChangeNotification
   object:self];
}

- (void)setUserPresentedWelcomeScreen:(BOOL)userPresentedScreen
{
  [[NSUserDefaults standardUserDefaults] setBool:userPresentedScreen forKey:userPresentedWelcomeScreenKey];
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
  if(renderingEngine == self.renderingEngine) return;
  
  [[NSUserDefaults standardUserDefaults] setObject:StringFromRenderingEngine(renderingEngine)
                                            forKey:renderingEngineKey];
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLSettingsDidChangeNotification
   object:self];
}

@end
