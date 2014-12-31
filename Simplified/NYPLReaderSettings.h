typedef NS_ENUM(NSInteger, NYPLReaderSettingsColorScheme) {
  NYPLReaderSettingsColorSchemeBlackOnWhite,
  NYPLReaderSettingsColorSchemeBlackOnSepia,
  NYPLReaderSettingsColorSchemeWhiteOnBlack
};

typedef NS_ENUM(NSInteger, NYPLReaderSettingsFontFace) {
  NYPLReaderSettingsFontFaceSans,
  NYPLReaderSettingsFontFaceSerif
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

static NSString *const NYPLReaderSettingsColorSchemeDidChangeNotification =
  @"NYPLReaderSettingsColorSchemeDidChange";

static NSString *const NYPLReaderSettingsFontFaceDidChangeNotification =
  @"NYPLReaderSettingsFontFaceDidChange";

static NSString *const NYPLReaderSettingsFontSizeDidChangeNotification =
  @"NYPLReaderSettingsFontSizeDidChange";

// Returns |YES| if output was set properly, else |NO| due to already being at the smallest size.
BOOL NYPLReaderSettingsDecreasedFontSize(NYPLReaderSettingsFontSize input,
                                         NYPLReaderSettingsFontSize *output);

// Returns |YES| if output was set properly, else |NO| due to already being at the largest size.
BOOL NYPLReaderSettingsIncreasedFontSize(NYPLReaderSettingsFontSize input,
                                         NYPLReaderSettingsFontSize *output);

@interface NYPLReaderSettings : NSObject

+ (NYPLReaderSettings *)sharedSettings;

@property (nonatomic, readonly) UIColor *backgroundColor;
@property (nonatomic) NYPLReaderSettingsColorScheme colorScheme;
@property (nonatomic) NYPLReaderSettingsFontFace fontFace;
@property (nonatomic) NYPLReaderSettingsFontSize fontSize;
@property (nonatomic, readonly) UIColor *foregroundColor;

- (void)save;

- (NSArray *)readiumStylesRepresentation;

- (NSDictionary *)readiumSettingsRepresentation;

@end
