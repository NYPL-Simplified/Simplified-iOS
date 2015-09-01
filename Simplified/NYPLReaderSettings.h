typedef NS_ENUM(NSInteger, NYPLReaderSettingsColorScheme) {
  NYPLReaderSettingsColorSchemeBlackOnWhite,
  NYPLReaderSettingsColorSchemeBlackOnSepia,
  NYPLReaderSettingsColorSchemeWhiteOnBlack
};

typedef NS_ENUM(NSInteger, NYPLReaderSettingsFontFace) {
  NYPLReaderSettingsFontFaceSans,
  NYPLReaderSettingsFontFaceSerif,
  NYPLReaderSettingsFontFaceOpenDyslexic
};

typedef NS_ENUM(NSInteger, NYPLReaderSettingsFontSize) {
  NYPLReaderSettingsFontSizeSmallest,
  NYPLReaderSettingsFontSizeSmaller,
  NYPLReaderSettingsFontSizeSmall,
  NYPLReaderSettingsFontSizeNormal,
  NYPLReaderSettingsFontSizeLarge,
  NYPLReaderSettingsFontSizeLarger,
  NYPLReaderSettingsFontSizeLargest
};

typedef NS_ENUM(NSInteger, NYPLReaderSettingsMediaOverlaysEnableClick) {
  NYPLReaderSettingsMediaOverlaysEnableClickTrue,
  NYPLReaderSettingsMediaOverlaysEnableClickFalse
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
@property (nonatomic) id currentReaderReadiumView;

- (void) toggleMediaOverlayPlayback;

- (void)save;

- (NSArray *)readiumStylesRepresentation;

- (NSDictionary *)readiumSettingsRepresentation;

@end
