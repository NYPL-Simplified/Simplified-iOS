static NSString *const NYPLSettingsDidChangeNotification = @"NYPLSettingsDidChangeNotification";

typedef NS_ENUM(NSInteger, NYPLSettingsRenderingEngine) {
  NYPLSettingsRenderingEngineAutomatic,
  NYPLSettingsRenderingEngineReadium
};

@interface NYPLSettings : NSObject

// Set to nil (the default) if no custom feed should be used.
@property (atomic) NSURL *customMainFeedURL;
@property (atomic) BOOL userAcceptedEULA;
@property (atomic) BOOL preloadContentCompleted;
@property (atomic) NSURL *eulaURL;
@property (atomic) NSURL *privacyPolicyURL;
@property (atomic) NSURL *acknowledgmentsURL;

// Leaving this set to |NYPLSettingsRenderingEngineAutomatic| (the default) is *highly* recommended.
@property (atomic) NYPLSettingsRenderingEngine renderingEngine;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (NYPLSettings *)sharedSettings;
- (NSArray *) preloadedBookIdentifiers;
- (NSArray *) booksToPreload;
- (NSArray *) booksToPreloadCurrentlyMissing;
- (NSArray *) booksToRestorePreloadedContentForIdentifiers: (NSArray *) identifiers;
@end
