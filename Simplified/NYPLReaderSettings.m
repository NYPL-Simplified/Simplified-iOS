#import "NYPLConfiguration.h"
#import "NYPLJSON.h"
#import "UIColor+NYPLColorAdditions.h"

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

NSString *fontFaceToString(NYPLReaderSettingsFontFace const fontFace)
{
  switch(fontFace) {
    case NYPLReaderSettingsFontFaceSans:
      return @"sans";
    case NYPLReaderSettingsFontFaceSerif:
      return @"serif";
  }
}

NYPLReaderSettingsFontFace fontFaceFromString(NSString *const string)
{
  NSNumber *const fontFaceNumber = @{@"sans": @(NYPLReaderSettingsFontFaceSans),
                                     @"serif": @(NYPLReaderSettingsFontFaceSerif)}[string];
  
  if(!fontFaceNumber) {
    @throw NSInvalidArgumentException;
  }
  
  return [fontFaceNumber integerValue];
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
    
    if(!savedData) {
      self.colorScheme = NYPLReaderSettingsColorSchemeBlackOnWhite;
      self.fontFace = NYPLReaderSettingsFontFaceSerif;
      self.fontSize = NYPLReaderSettingsFontSizeNormal;
      return;
    }
    
    NSDictionary *const dictionary = NYPLJSONObjectFromData(savedData);
    
    if(!dictionary) {
      NYPLLOG(@"Failed to interpret saved registry data as JSON.");
      return;
    }
    
    self.colorScheme = colorSchemeFromString(dictionary[ColorSchemeKey]);
    self.fontFace = fontFaceFromString(dictionary[FontFaceKey]);
    self.fontSize = fontSizeFromString(dictionary[FontSizeKey]);
  }
}

- (NSDictionary *)dictionaryRepresentation
{
  return @{ColorSchemeKey: colorSchemeToString(self.colorScheme),
           FontFaceKey: fontFaceToString(self.fontFace),
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

- (void)setColorScheme:(NYPLReaderSettingsColorScheme const)colorScheme
{
  _colorScheme = colorScheme;
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLReaderSettingsColorSchemeDidChangeNotification
   object:self];
}

- (void)setFontFace:(NYPLReaderSettingsFontFace const)fontFace
{
  _fontFace = fontFace;
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLReaderSettingsFontFaceDidChangeNotification
   object:self];
}

- (void)setFontSize:(NYPLReaderSettingsFontSize const)fontSize
{
  _fontSize = fontSize;
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLReaderSettingsFontSizeDidChangeNotification
   object:self];
}

- (UIColor *)backgroundColor
{
  switch(self.colorScheme) {
    case NYPLReaderSettingsColorSchemeBlackOnSepia:
      return [NYPLConfiguration backgroundSepiaColor];
    case NYPLReaderSettingsColorSchemeBlackOnWhite:
      return [NYPLConfiguration backgroundColor];
    case NYPLReaderSettingsColorSchemeWhiteOnBlack:
      return [NYPLConfiguration backgroundDarkColor];
  }
}

- (UIColor *)foregroundColor
{
  switch(self.colorScheme) {
    case NYPLReaderSettingsColorSchemeBlackOnSepia:
      return [UIColor blackColor];
    case NYPLReaderSettingsColorSchemeBlackOnWhite:
      return [UIColor blackColor];
    case NYPLReaderSettingsColorSchemeWhiteOnBlack:
      return [UIColor whiteColor];
  }
}

- (NSArray *)readiumStylesRepresentation
{
  NSString *fontFace;
  NSString *lineHeight;
  
  switch(self.fontFace) {
    case NYPLReaderSettingsFontFaceSans:
      fontFace = @"HelveticaNeue";
      lineHeight = @"1.6";
      break;
    case NYPLReaderSettingsFontFaceSerif:
      fontFace = @"Georgia";
      lineHeight = @"1.6";
      break;
  }
  
  return @[@{@"selector": @"body",
             @"declarations": @{@"color": [self.foregroundColor javascriptHexString],
                                @"backgroundColor": [self.backgroundColor javascriptHexString],
                                @"font-face": fontFace,
                                @"line-height": lineHeight,
                                @"-webkit-hyphens": @"auto"}}];
}

- (NSDictionary *)readiumSettingsRepresentation
{
  CGFloat const scalingFactor = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 1.3 : 0.9;
  
  CGFloat baseSize;
  switch(self.fontSize) {
    case NYPLReaderSettingsFontSizeSmallest:
      baseSize = 70;
      break;
    case NYPLReaderSettingsFontSizeSmaller:
      baseSize = 80;
      break;
    case NYPLReaderSettingsFontSizeSmall:
      baseSize = 90;
      break;
    case NYPLReaderSettingsFontSizeNormal:
      baseSize = 100;
      break;
    case NYPLReaderSettingsFontSizeLarge:
      baseSize = 115;
      break;
    case NYPLReaderSettingsFontSizeLarger:
      baseSize = 130;
      break;
    case NYPLReaderSettingsFontSizeLargest:
      baseSize = 145;
      break;
  }
  
  return @{@"columnGap": @20,
           @"fontSize": @(baseSize * scalingFactor),
           @"syntheticSpread": @NO};
}

@end
