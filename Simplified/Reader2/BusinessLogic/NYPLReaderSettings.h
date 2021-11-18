// FIXME: These values should be persisted as strings, not numbers derived
// from an enum.

typedef NS_CLOSED_ENUM(NSInteger, NYPLReaderSettingsColorScheme) {
  NYPLReaderSettingsColorSchemeBlackOnWhite = 0,
  NYPLReaderSettingsColorSchemeBlackOnSepia = 1,
  NYPLReaderSettingsColorSchemeWhiteOnBlack = 2
};

typedef NS_CLOSED_ENUM(NSInteger, NYPLReaderSettingsFontFace) {
  NYPLReaderSettingsFontFaceSans = 0,
  NYPLReaderSettingsFontFaceSerif = 1,
  NYPLReaderSettingsFontFaceOpenDyslexic = 2
};

typedef NS_CLOSED_ENUM(NSInteger, NYPLReaderSettingsFontSize) {
  NYPLReaderSettingsFontSizeSmallest = 0,
  NYPLReaderSettingsFontSizeSmaller = 1,
  NYPLReaderSettingsFontSizeSmall = 2,
  NYPLReaderSettingsFontSizeNormal = 3,
  NYPLReaderSettingsFontSizeLarge = 4,
  NYPLReaderSettingsFontSizeXLarge = 5,
  NYPLReaderSettingsFontSizeXXLarge = 6,
  NYPLReaderSettingsFontSizeXXXLarge = 7,
  NYPLReaderSettingsFontSizeLargest = 7
};

typedef NS_CLOSED_ENUM(NSInteger, NYPLReaderSettingsMediaOverlaysEnableClick) {
  NYPLReaderSettingsMediaOverlaysEnableClickTrue = 0,
  NYPLReaderSettingsMediaOverlaysEnableClickFalse = 1
};

extern NSString * _Nonnull const NYPLReaderSettingsColorSchemeDidChangeNotification;
extern NSString * _Nonnull const NYPLReaderSettingsFontFaceDidChangeNotification;
extern NSString * _Nonnull const NYPLReaderSettingsFontSizeDidChangeNotification;
extern NSString * _Nonnull const NYPLReaderSettingsMediaClickOverlayAlwaysEnableDidChangeNotification;


// Returns |YES| if output was set properly, else |NO| due to already being at the smallest size.
BOOL NYPLReaderSettingsDecreasedFontSize(NYPLReaderSettingsFontSize input,
                                         NYPLReaderSettingsFontSize * _Nullable output);

// Returns |YES| if output was set properly, else |NO| due to already being at the largest size.
BOOL NYPLReaderSettingsIncreasedFontSize(NYPLReaderSettingsFontSize input,
                                         NYPLReaderSettingsFontSize * _Nullable output);

@interface NYPLReaderSettings : NSObject

+ (nonnull NYPLReaderSettings *)sharedSettings;

@property (nonatomic) NYPLReaderSettingsColorScheme colorScheme;
@property (nonatomic) NYPLReaderSettingsFontFace fontFace;
@property (nonatomic) NYPLReaderSettingsFontSize fontSize;
@property (nonatomic) NYPLReaderSettingsMediaOverlaysEnableClick mediaOverlaysEnableClick;
@property (nonnull, nonatomic, readonly) UIColor *backgroundColor;
@property (nonnull, nonatomic, readonly) UIColor *backgroundMediaOverlayHighlightColor;
@property (nonnull, nonatomic, readonly) UIColor *foregroundColor;
@property (nonnull, nonatomic, readonly) UIColor *selectedForegroundColor;
@property (nonnull, nonatomic, readonly) UIColor *tintColor;

- (void)save;

- (nonnull NSArray *)readiumStylesRepresentation;

- (nonnull NSDictionary *)readiumSettingsRepresentation;

@end
