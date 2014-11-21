#import "NYPLReaderSettings.h"

@class NYPLReaderSettingsView;

@protocol NYPLReaderSettingsViewDelegate

- (void)readerSettingsView:(NYPLReaderSettingsView *)readerSettingsView
       didSelectBrightness:(CGFloat)brightness;

- (void)readerSettingsView:(NYPLReaderSettingsView *)readerSettingsView
      didSelectColorScheme:(NYPLReaderSettingsColorScheme)colorScheme;

- (void)readerSettingsView:(NYPLReaderSettingsView *)readerSettingsView
         didSelectFontSize:(NYPLReaderSettingsFontSize)fontSize;

- (void)readerSettingsView:(NYPLReaderSettingsView *)readerSettingsView
         didSelectFontType:(NYPLReaderSettingsFontType)fontType;

@end

@interface NYPLReaderSettingsView : UIView

// This class observes brightness change notifications from UIScreen and reflects them visually. It
// does not, however, change the screen's brightness itself. Objects that use this view should
// implement its delegate and forward brightness changes to a UIScreen instance as appropriate.
@property (nonatomic) NYPLReaderSettingsColorScheme colorScheme;
@property (nonatomic, weak) id<NYPLReaderSettingsViewDelegate> delegate;
@property (nonatomic) NYPLReaderSettingsFontSize fontSize;
@property (nonatomic) NYPLReaderSettingsFontType fontType;

- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

@end
