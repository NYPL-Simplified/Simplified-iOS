static NSString *const NYPLSettingsDidChangeNotification = @"NYPLSettingsDidChangeNotification";
static NSString *const NYPLCurrentAccountDidChangeNotification = @"NYPLCurrentAccountDidChangeNotification";

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
@property (atomic) BOOL userPresentedWelcomeScreen;
@property (atomic) NYPLCardApplicationModel *currentCardApplication;

@property (readonly) Account* currentAccount;
@property (atomic) NSInteger currentAccountIdentifier;
@property (atomic) NSArray* settingsAccountsList;

// Leaving this set to |NYPLSettingsRenderingEngineAutomatic| (the default) is *highly* recommended.
@property (atomic) NYPLSettingsRenderingEngine renderingEngine;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (NYPLSettings *)sharedSettings;

@end
