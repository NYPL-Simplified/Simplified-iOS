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

// Returns |YES| if output was set properly, else |NO| due to already being at the smallest size.
BOOL NYPLReaderSettingsDecreasedFontSize(NYPLReaderSettingsFontSize input,
                                         NYPLReaderSettingsFontSize *output);

// Returns |YES| if output was set properly, else |NO| due to already being at the largest size.
BOOL NYPLReaderSettingsIncreasedFontSize(NYPLReaderSettingsFontSize input,
                                         NYPLReaderSettingsFontSize *output);

@interface NYPLReaderSettings : NSObject

+ (NYPLReaderSettings *)sharedSettings;

@property (nonatomic) NYPLReaderSettingsColorScheme colorScheme;
@property (nonatomic) NYPLReaderSettingsFontSize fontSize;
@property (nonatomic) NYPLReaderSettingsFontFace fontFace;

- (void)save;

@end
