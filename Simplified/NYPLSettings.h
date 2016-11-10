static NSString *const NYPLSettingsDidChangeNotification = @"NYPLSettingsDidChangeNotification";

typedef NS_ENUM(NSInteger, NYPLSettingsRenderingEngine) {
  NYPLSettingsRenderingEngineAutomatic,
  NYPLSettingsRenderingEngineReadium
};

@class NYPLCardApplicationModel;

@interface NYPLSettings : NSObject

// Set to nil (the default) if no custom feed should be used.
@property (atomic) NSURL *customMainFeedURL;
@property (atomic) BOOL userAcceptedEULA;
@property (atomic) NSURL *eulaURL;
@property (atomic) NSURL *privacyPolicyURL;
@property (atomic) NSURL *acknowledgmentsURL;
@property (atomic) NSURL *contentLicenseURL;
@property (atomic) NYPLCardApplicationModel *currentCardApplication;

@property (atomic) NSString* currentAccount;
@property (atomic) NSArray* settingsAccountsList;

// Leaving this set to |NYPLSettingsRenderingEngineAutomatic| (the default) is *highly* recommended.
@property (atomic) NYPLSettingsRenderingEngine renderingEngine;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (NYPLSettings *)sharedSettings;

@end
