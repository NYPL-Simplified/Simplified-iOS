static NSString *const NYPLSettingsDidChangeNotification = @"NYPLSettingsDidChangeNotification";
static NSString *const NYPLCurrentAccountDidChangeNotification = @"NYPLCurrentAccountDidChangeNotification";
static NSString *const NYPLSyncBeganNotification = @"NYPLSyncBeganNotification";
static NSString *const NYPLSyncEndedNotification = @"NYPLSyncEndedNotification";

static NSString *const userHasSeenWelcomeScreenKey = @"NYPLUserHasSeenWelcomeScreenKey";

typedef NS_ENUM(NSInteger, NYPLSettingsRenderingEngine) {
  NYPLSettingsRenderingEngineAutomatic,
  NYPLSettingsRenderingEngineReadium
};

@class NYPLCardApplicationModel;
@class Account;

static NSString *const NYPLAcknowledgementsURLString = @"http://www.librarysimplified.org/acknowledgments.html";
static NSString *const NYPLUserAgreementURLString = @"http://www.librarysimplified.org/EULA.html";

@interface NYPLSettings : NSObject

// Set to nil (the default) if no custom feed should be used.
@property (atomic) NSURL *customMainFeedURL;
@property (atomic) NSURL *accountMainFeedURL;
@property (atomic) BOOL userHasSeenWelcomeScreen;
@property (atomic) BOOL userPresentedAgeCheck;
@property (atomic) BOOL userHasSeenFirstTimeSyncMessage;
@property (atomic) NYPLCardApplicationModel *currentCardApplication;
@property (atomic) NSArray* settingsAccountsList;

// Leaving this set to |NYPLSettingsRenderingEngineAutomatic| (the default) is *highly* recommended.
@property (atomic) NYPLSettingsRenderingEngine renderingEngine;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (NYPLSettings *)sharedSettings;

@end
