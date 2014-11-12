@class NYPLReaderSettingsView;

// Should always have range [0, 1].
typedef CGFloat NYPLReaderSettingsViewBrightness;

// Do not reorder.
typedef NS_ENUM(NSInteger, NYPLReaderSettingsViewFontSize) {
  NYPLReaderSettingsViewFontSizeSmallest,
  NYPLReaderSettingsViewFontSizeSmaller,
  NYPLReaderSettingsViewFontSizeSmall,
  NYPLReaderSettingsViewFontSizeNormal,
  NYPLReaderSettingsViewFontSizeLarge,
  NYPLReaderSettingsViewFontSizeLarger,
  NYPLReaderSettingsViewFontSizeLargest
};

// Do not reorder.
typedef NS_ENUM(NSInteger, NYPLReaderSettingsViewColorScheme) {
  NYPLReaderSettingsViewColorSchemeBlackOnWhite,
  NYPLReaderSettingsViewColorSchemeBlackOnSepia,
  NYPLReaderSettingsViewColorSchemeWhiteOnBlack
};

@protocol NYPLReaderSettingsViewDelegate

- (void)readerSettingsView:(NYPLReaderSettingsView *)readerSettingsView
       didSelectBrightness:(NYPLReaderSettingsViewBrightness)brightness;

- (void)readerSettingsView:(NYPLReaderSettingsView *)readerSettingsView
      didSelectColorScheme:(NYPLReaderSettingsViewColorScheme)colorScheme;

- (void)readerSettingsView:(NYPLReaderSettingsView *)readerSettingsView
         didSelectFontSize:(NYPLReaderSettingsViewFontSize)fontSize;

@end

@interface NYPLReaderSettingsView : UIView

// This class observes brightness change notifications from UIScreen and reflects them visually. It
// does not, however, change the screen's brightness itself. Objects that use this view should
// implement its delegate and forward brightness changes to a UIScreen instance as appropriate.
@property (nonatomic) NYPLReaderSettingsViewBrightness brightness;
@property (nonatomic) NYPLReaderSettingsViewColorScheme colorScheme;
@property (nonatomic, weak) id<NYPLReaderSettingsViewDelegate> delegate;
@property (nonatomic) NYPLReaderSettingsViewFontSize fontSize;

- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

@end
