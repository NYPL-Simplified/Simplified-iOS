// Do not reorder.
typedef NS_ENUM(NSInteger, NYPLReaderSettingsColorScheme) {
  NYPLReaderSettingsColorSchemeBlackOnWhite,
  NYPLReaderSettingsColorSchemeBlackOnSepia,
  NYPLReaderSettingsColorSchemeWhiteOnBlack
};

// Do not reorder.
typedef NS_ENUM(NSInteger, NYPLReaderSettingsFontSize) {
  NYPLReaderSettingsFontSizeSmallest,
  NYPLReaderSettingsFontSizeSmaller,
  NYPLReaderSettingsFontSizeSmall,
  NYPLReaderSettingsFontSizeNormal,
  NYPLReaderSettingsFontSizeLarge,
  NYPLReaderSettingsFontSizeLarger,
  NYPLReaderSettingsFontSizeLargest
};

// Do not reorder.
typedef NS_ENUM(NSInteger, NYPLReaderSettingsFontType) {
  NYPLReaderSettingsFontTypeSans,
  NYPLReaderSettingsFontTypeSerif
};

@interface NYPLReaderSettings : NSObject

+ (NYPLReaderSettings *)sharedReaderSettings;

@property (nonatomic) NYPLReaderSettingsColorScheme colorScheme;
@property (nonatomic) NYPLReaderSettingsFontSize fontSize;
@property (nonatomic) NYPLReaderSettingsFontType fontType;

@end
