#import "NYPLReaderSettings.h"

@class NYPLReaderSettingsView;

//==============================================================================

typedef NS_ENUM(NSUInteger, NYPLReaderFontSizeChange) {
  NYPLReaderFontSizeChangeIncrease,
  NYPLReaderFontSizeChangeDecrease,
};

@protocol NYPLReaderSettingsViewDelegate

- (void)readerSettingsView:(nonnull NYPLReaderSettingsView *)readerSettingsView
       didSelectBrightness:(CGFloat)brightness;

- (void)readerSettingsView:(nonnull NYPLReaderSettingsView *)readerSettingsView
      didSelectColorScheme:(NYPLReaderSettingsColorScheme)colorScheme;

- (NYPLReaderSettingsFontSize)readerSettingsView:(nonnull NYPLReaderSettingsView *)view
                               didChangeFontSize:(NYPLReaderFontSizeChange)change;

- (void)readerSettingsView:(nonnull NYPLReaderSettingsView *)readerSettingsView
         didSelectFontFace:(NYPLReaderSettingsFontFace)fontFace;

@end

//==============================================================================
/**
 This class observes brightness change notifications from UIScreen and reflects
 them visually. It does not, however, change the screen's brightness itself.
 Objects that use this view should implement its delegate and forward
 brightness changes to a UIScreen instance as appropriate.
 */
@interface NYPLReaderSettingsView : UIView

@property (nonatomic) NYPLReaderSettingsColorScheme colorScheme;
@property (nonatomic, weak, nullable) id<NYPLReaderSettingsViewDelegate> delegate;
@property (nonatomic) NYPLReaderSettingsFontSize fontSize;
@property (nonatomic) NYPLReaderSettingsFontFace fontFace;

+ (nonnull instancetype)new NS_UNAVAILABLE;
- (nonnull instancetype)init NS_UNAVAILABLE;
- (nonnull instancetype)initWithCoder:(nonnull NSCoder *)aDecoder NS_UNAVAILABLE;
- (nonnull instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nonnull instancetype)initWithWidth:(CGFloat)width;

@end
