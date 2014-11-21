#import "NYPLJSON.h"

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

NSString *colorSchemeToString(NYPLReaderSettingsColorScheme const colorScheme)
{
  switch(colorScheme) {
    case NYPLReaderSettingsColorSchemeBlackOnSepia:
      return @"blackOnSepia";
    case NYPLReaderSettingsColorSchemeBlackOnWhite:
      return @"blackOnWhite";
    case NYPLReaderSettingsColorSchemeWhiteOnBlack:
      return @"whiteOnBlack";
  }
}

NYPLReaderSettingsColorScheme colorSchemeFromString(NSString *const string)
{
  NSNumber *const colorSchemeNumber =
    @{@"blackOnSepia": @(NYPLReaderSettingsColorSchemeBlackOnSepia),
      @"blackOnWhite": @(NYPLReaderSettingsColorSchemeBlackOnWhite),
      @"whiteOnBlack": @(NYPLReaderSettingsColorSchemeWhiteOnBlack)}[string];
  
  if(!colorSchemeNumber) {
    @throw NSInvalidArgumentException;
  }
  
  return [colorSchemeNumber integerValue];
}

NSString *fontFaceToString(NYPLReaderSettingsFontType const fontFace)
{
  switch(fontFace) {
    case NYPLReaderSettingsFontTypeSans:
      return @"sans";
    case NYPLReaderSettingsFontTypeSerif:
      return @"serif";
  }
}

NYPLReaderSettingsFontType fontFaceFromString(NSString *const string)
{
  NSNumber *const fontTypeNumber = @{@"sans": @(NYPLReaderSettingsFontTypeSans),
                                     @"serif": @(NYPLReaderSettingsFontTypeSerif)}[string];
  
  if(!fontTypeNumber) {
    @throw NSInvalidArgumentException;
  }
  
  return [fontTypeNumber integerValue];
}

NSString *fontSizeToString(NYPLReaderSettingsFontSize const fontSize)
{
  switch(fontSize) {
    case NYPLReaderSettingsFontSizeSmallest:
      return @"smallest";
    case NYPLReaderSettingsFontSizeSmaller:
      return @"smaller";
    case NYPLReaderSettingsFontSizeSmall:
      return @"small";
    case NYPLReaderSettingsFontSizeNormal:
      return @"normal";
    case NYPLReaderSettingsFontSizeLarge:
      return @"large";
    case NYPLReaderSettingsFontSizeLarger:
      return @"larger";
    case NYPLReaderSettingsFontSizeLargest:
      return @"largest";
  }
}

NYPLReaderSettingsFontSize fontSizeFromString(NSString *const string)
{
  NSNumber *const fontSizeNumber = @{@"smallest": @(NYPLReaderSettingsFontSizeSmallest),
                                     @"smaller": @(NYPLReaderSettingsFontSizeSmaller),
                                     @"small": @(NYPLReaderSettingsFontSizeSmall),
                                     @"normal": @(NYPLReaderSettingsFontSizeNormal),
                                     @"large": @(NYPLReaderSettingsFontSizeLarge),
                                     @"larger": @(NYPLReaderSettingsFontSizeLarger),
                                     @"largest": @(NYPLReaderSettingsFontSizeLargest)}[string];
  
  if(!fontSizeNumber) {
    @throw NSInvalidArgumentException;
  }
  
  return [fontSizeNumber integerValue];
}

static NSString *const ColorSchemeKey = @"colorScheme";
static NSString *const FontFaceKey = @"fontFace";
static NSString *const FontSizeKey = @"fontSize";

@implementation NYPLReaderSettings

+ (NYPLReaderSettings *)sharedSettings
{
  static dispatch_once_t predicate;
  static NYPLReaderSettings *sharedReaderSettings = nil;
  
  dispatch_once(&predicate, ^{
    sharedReaderSettings = [[self alloc] init];
    if(!sharedReaderSettings) {
      NYPLLOG(@"Failed to create shared reader settings.");
    }
    
    [sharedReaderSettings load];
  });
  
  return sharedReaderSettings;
}

- (NSURL *)settingsURL
{
  NSArray *const paths =
    NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
  
  assert([paths count] == 1);
  
  NSString *const path = paths[0];
  
  return [[[NSURL fileURLWithPath:path]
           URLByAppendingPathComponent:[[NSBundle mainBundle]
                                        objectForInfoDictionaryKey:@"CFBundleIdentifier"]]
          URLByAppendingPathComponent:@"settings.json"];
}

- (void)load
{
  @synchronized(self) {
    NSData *const savedData = [NSData dataWithContentsOfURL:[self settingsURL]];
    
    if(!savedData) return;
    
    NSDictionary *const dictionary = NYPLJSONObjectFromData(savedData);
    
    if(!dictionary) {
      NYPLLOG(@"Failed to interpret saved registry data as JSON.");
      return;
    }
    
    self.colorScheme = colorSchemeFromString(dictionary[ColorSchemeKey]);
    self.fontType = fontFaceFromString(dictionary[FontFaceKey]);
    self.fontSize = fontSizeFromString(dictionary[FontSizeKey]);
  }
}

- (NSDictionary *)dictionaryRepresentation
{
  return @{ColorSchemeKey: colorSchemeToString(self.colorScheme),
           FontFaceKey: fontFaceToString(self.fontType),
           FontSizeKey: fontSizeToString(self.fontSize)};
}

- (void)save
{
  @synchronized(self) {
    NSOutputStream *const stream =
      [NSOutputStream outputStreamWithURL:[[self settingsURL] URLByAppendingPathExtension:@"temp"]
                                   append:NO];
    
    [stream open];
    
    // This try block is necessary to catch an (entirely undocumented) exception thrown by
    // NSJSONSerialization in the event that the provided stream isn't open for writing.
    @try {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wassign-enum"
      if(![NSJSONSerialization
           writeJSONObject:[self dictionaryRepresentation]
           toStream:stream
           options:0
           error:NULL]) {
#pragma clang diagnostic pop
        NYPLLOG(@"Failed to write settings data.");
        return;
      }
    } @catch(NSException *const exception) {
      NYPLLOG_F(@"Exception: %@: %@", [exception name], [exception reason]);
      return;
    } @finally {
      [stream close];
    }
    
    if(![[NSFileManager defaultManager]
         replaceItemAtURL:[self settingsURL]
         withItemAtURL:[[self settingsURL] URLByAppendingPathExtension:@"temp"]
         backupItemName:nil
         options:NSFileManagerItemReplacementUsingNewMetadataOnly
         resultingItemURL:NULL
         error:NULL]) {
      NYPLLOG(@"Failed to rename temporary settings file.");
      return;
    }
  }
}

@end
