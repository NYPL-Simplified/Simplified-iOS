// FIXME: These values should be persisted as strings, not numbers derived
// from an enum.

typedef NS_ENUM(NSInteger, NYPLReaderSettingsColorScheme) {
  NYPLReaderSettingsColorSchemeBlackOnWhite = 0,
  NYPLReaderSettingsColorSchemeBlackOnSepia = 1,
  NYPLReaderSettingsColorSchemeWhiteOnBlack = 2
};

typedef NS_ENUM(NSInteger, NYPLReaderSettingsFontFace) {
  NYPLReaderSettingsFontFaceSans = 0,
  NYPLReaderSettingsFontFaceSerif = 1,
  NYPLReaderSettingsFontFaceOpenDyslexic = 2
};

typedef NS_ENUM(NSInteger, NYPLReaderSettingsFontSize) {
  NYPLReaderSettingsFontSizeSmallest = 0,
  NYPLReaderSettingsFontSizeSmaller = 1,
  NYPLReaderSettingsFontSizeSmall = 2,
  NYPLReaderSettingsFontSizeNormal = 3,
  NYPLReaderSettingsFontSizeLarge = 4,
  NYPLReaderSettingsFontSizeXLarge = 5,
  NYPLReaderSettingsFontSizeXXLarge = 6,
  NYPLReaderSettingsFontSizeXXXLarge = 7
};

typedef NS_ENUM(NSInteger, NYPLReaderSettingsMediaOverlaysEnableClick) {
  NYPLReaderSettingsMediaOverlaysEnableClickTrue = 0,
  NYPLReaderSettingsMediaOverlaysEnableClickFalse = 1
};

static NSString *const NYPLReaderSettingsColorSchemeDidChangeNotification =
  @"NYPLReaderSettingsColorSchemeDidChange";

static NSString *const NYPLReaderSettingsFontFaceDidChangeNotification =
  @"NYPLReaderSettingsFontFaceDidChange";

static NSString *const NYPLReaderSettingsFontSizeDidChangeNotification =
  @"NYPLReaderSettingsFontSizeDidChange";

static NSString *const NYPLReaderSettingsMediaClickOverlayAlwaysEnableDidChangeNotification =
@"NYPLReaderSettingsMediaClickOverlayAlwaysEnableDidChangeNotification";

static NSString *const NYPLReaderSettingsMediaOverlayPlaybackToggleDidChangeNotification =
@"NYPLReaderSettingsMediaOverlayPlaybackToggleDidChangeNotification";

// Returns |YES| if output was set properly, else |NO| due to already being at the smallest size.
BOOL NYPLReaderSettingsDecreasedFontSize(NYPLReaderSettingsFontSize input,
                                         NYPLReaderSettingsFontSize *output);

// Returns |YES| if output was set properly, else |NO| due to already being at the largest size.
BOOL NYPLReaderSettingsIncreasedFontSize(NYPLReaderSettingsFontSize input,
                                         NYPLReaderSettingsFontSize *output);

@interface NYPLReaderSettings : NSObject

+ (NYPLReaderSettings *)sharedSettings;

@property (nonatomic, readonly) UIColor *backgroundColor;
@property (nonatomic, readonly) UIColor *backgroundMediaOverlayHighlightColor;
@property (nonatomic) NYPLReaderSettingsColorScheme colorScheme;
@property (nonatomic) NYPLReaderSettingsFontFace fontFace;
@property (nonatomic) NYPLReaderSettingsFontSize fontSize;
@property (nonatomic) NYPLReaderSettingsMediaOverlaysEnableClick mediaOverlaysEnableClick;
@property (nonatomic, readonly) UIColor *foregroundColor;
@property (nonatomic, weak) id currentReaderReadiumView;

- (void) toggleMediaOverlayPlayback;

- (void)save;

- (NSArray *)readiumStylesRepresentation;

- (NSDictionary *)readiumSettingsRepresentation;

@end
