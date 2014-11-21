#import "NYPLReaderSettings.h"

BOOL NYPLReaderSettingsDecreasedFontSize(NYPLReaderSettingsFontSize const input,
                                                NYPLReaderSettingsFontSize *const output)
{
  switch(input) {
    case NYPLReaderSettingsFontSizeSmallest:
      return NO;
    case NYPLReaderSettingsFontSizeSmaller:
      *output = NYPLReaderSettingsFontSizeSmallest;
      return YES;
    case NYPLReaderSettingsFontSizeSmall:
      *output = NYPLReaderSettingsFontSizeSmaller;
      return YES;
    case NYPLReaderSettingsFontSizeNormal:
      *output = NYPLReaderSettingsFontSizeSmall;
      return YES;
    case NYPLReaderSettingsFontSizeLarge:
      *output = NYPLReaderSettingsFontSizeNormal;
      return YES;
    case NYPLReaderSettingsFontSizeLarger:
      *output = NYPLReaderSettingsFontSizeLarge;
      return YES;
    case NYPLReaderSettingsFontSizeLargest:
      *output = NYPLReaderSettingsFontSizeLarger;
      return YES;
  }
}

BOOL NYPLReaderSettingsIncreasedFontSize(NYPLReaderSettingsFontSize const input,
                                         NYPLReaderSettingsFontSize *const output)
{
  switch(input) {
    case NYPLReaderSettingsFontSizeSmallest:
      *output = NYPLReaderSettingsFontSizeSmaller;
      return YES;
    case NYPLReaderSettingsFontSizeSmaller:
      *output = NYPLReaderSettingsFontSizeSmall;
      return YES;
    case NYPLReaderSettingsFontSizeSmall:
      *output = NYPLReaderSettingsFontSizeNormal;
      return YES;
    case NYPLReaderSettingsFontSizeNormal:
      *output = NYPLReaderSettingsFontSizeLarge;
      return YES;
    case NYPLReaderSettingsFontSizeLarge:
      *output = NYPLReaderSettingsFontSizeLarger;
      return YES;
    case NYPLReaderSettingsFontSizeLarger:
      *output = NYPLReaderSettingsFontSizeLargest;
      return YES;
    case NYPLReaderSettingsFontSizeLargest:
      return NO;
  }
}

@implementation NYPLReaderSettings

+ (NYPLReaderSettings *)sharedReaderSettings
{
  static dispatch_once_t predicate;
  static NYPLReaderSettings *sharedReaderSettings = nil;
  
  dispatch_once(&predicate, ^{
    sharedReaderSettings = [[self alloc] init];
    if(!sharedReaderSettings) {
      NYPLLOG(@"Failed to create shared reader settings.");
    }
  });
  
  return sharedReaderSettings;
}

@end
