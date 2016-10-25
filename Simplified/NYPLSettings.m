#import "NYPLSettings.h"
#import "NYPLBookAcquisition.h"
#import "NSDate+NYPLDateAdditions.h"
#import "NYPLBook.h"
#import "NYPLBookRegistry.h"
#import "NYPLConfiguration.h"

static NSString *const customMainFeedURLKey = @"NYPLSettingsCustomMainFeedURL";

static NSString *const renderingEngineKey = @"NYPLSettingsRenderingEngine";

static NSString *const userAcceptedEULAKey = @"NYPLSettingsUserAcceptedEULA";

static NSString *const eulaURLKey = @"NYPLSettingsEULAURL";

static NSString *const privacyPolicyURLKey = @"NYPLSettingsPrivacyPolicyURL";

static NSString *const acknowledgmentsURLKey = @"NYPLSettingsAcknowledgmentsURL";

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
