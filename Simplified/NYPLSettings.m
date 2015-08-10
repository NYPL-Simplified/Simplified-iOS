#import "NYPLSettings.h"

static NSString *const customMainFeedURLKey = @"NYPLSettingsCustomMainFeedURL";

static NSString *const renderingEngineKey = @"NYPLSettingsRenderingEngine";

static NSString *const userAcceptedEULAKey = @"NYPLSettingsUserAcceptedEULA";

static NSString *const eulaURLKey = @"NYPLSettingsEULAURL";

static NSString *const privacyPolicyURLKey = @"NYPLSettingsPrivacyPolicyURL";

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
