#import "NYPLConfiguration.h"
#import "NYPLJSON.h"
#import "UIColor+NYPLColorAdditions.h"

#import "NYPLReaderSettings.h"

#import "SimplyE-Swift.h"

NSString *const NYPLReaderSettingsColorSchemeDidChangeNotification =
@"NYPLReaderSettingsColorSchemeDidChange";

NSString *const NYPLReaderSettingsFontFaceDidChangeNotification =
@"NYPLReaderSettingsFontFaceDidChange";

NSString *const NYPLReaderSettingsFontSizeDidChangeNotification =
@"NYPLReaderSettingsFontSizeDidChange";

NSString *const NYPLReaderSettingsMediaClickOverlayAlwaysEnableDidChangeNotification =
@"NYPLReaderSettingsMediaClickOverlayAlwaysEnableDidChangeNotification";

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
    case NYPLReaderSettingsFontSizeXLarge:
      *output = NYPLReaderSettingsFontSizeLarge;
      return YES;
    case NYPLReaderSettingsFontSizeXXLarge:
      *output = NYPLReaderSettingsFontSizeXLarge;
      return YES;
    case NYPLReaderSettingsFontSizeXXXLarge:
      *output = NYPLReaderSettingsFontSizeXXLarge;
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
      *output = NYPLReaderSettingsFontSizeXLarge;
      return YES;
    case NYPLReaderSettingsFontSizeXLarge:
      *output = NYPLReaderSettingsFontSizeXXLarge;
      return YES;
    case NYPLReaderSettingsFontSizeXXLarge:
      *output = NYPLReaderSettingsFontSizeXXXLarge;
      return YES;
    case NYPLReaderSettingsFontSizeXXXLarge:
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
    @throw NSInternalInconsistencyException;
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
    case NYPLReaderSettingsFontFaceOpenDyslexic:
      return @"OpenDyslexic";
  }
}

NYPLReaderSettingsFontFace fontFaceFromString(NSString *const stringKey)
{
  NSDictionary *possibleValues = @{
    @"sans": @(NYPLReaderSettingsFontFaceSans),
    @"serif": @(NYPLReaderSettingsFontFaceSerif),
    @"OpenDyslexic": @(NYPLReaderSettingsFontFaceOpenDyslexic),
    @"OpenDyslexic3": @(NYPLReaderSettingsFontFaceOpenDyslexic)
  };
  NSNumber *fontFaceNumber = possibleValues[stringKey];
  
  if(fontFaceNumber == nil) {
#if DEBUG
    @throw NSInternalInconsistencyException;
#else
    fontFaceNumber = @(NYPLReaderSettingsFontFaceSans);
#endif
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
    case NYPLReaderSettingsFontSizeXLarge:
      return @"xlarge";
    case NYPLReaderSettingsFontSizeXXLarge:
      return @"xxlarge";
    case NYPLReaderSettingsFontSizeXXXLarge:
      return @"xxxlarge";
  }
}

BOOL mediaOverlaysEnableClickToBOOL(NSString * mediaClickOverlayAlwaysEnable)
{
  if ([mediaClickOverlayAlwaysEnable isEqualToString:@"true"]) {
    return YES;
  }
  else {
    return NO;
  }
}

NSString * mediaOverlaysEnableClickToString(BOOL mediaClickOverlayAlwaysEnable)
{
  if (mediaClickOverlayAlwaysEnable) {
    return @"true";
  }
  else {
    return @"false";
  }
}

NYPLReaderSettingsFontSize fontSizeFromString(NSString *const string)
{
  // Had to re-add older keys 'larger' and 'largest' to save from a
  // crash for versions before 2.0.0 (1087)
  NSNumber *const fontSizeNumber = @{@"smallest": @(NYPLReaderSettingsFontSizeSmallest),
                                     @"smaller": @(NYPLReaderSettingsFontSizeSmaller),
                                     @"small": @(NYPLReaderSettingsFontSizeSmall),
                                     @"normal": @(NYPLReaderSettingsFontSizeNormal),
                                     @"large": @(NYPLReaderSettingsFontSizeLarge),
                                     @"larger": @(NYPLReaderSettingsFontSizeXLarge),
                                     @"largest": @(NYPLReaderSettingsFontSizeXXLarge),
                                     @"xlarge": @(NYPLReaderSettingsFontSizeXLarge),
                                     @"xxlarge": @(NYPLReaderSettingsFontSizeXXLarge),
                                     @"xxxlarge": @(NYPLReaderSettingsFontSizeXXXLarge)}[string];
  
  if(!fontSizeNumber) {
    @throw NSInternalInconsistencyException;
  }
  
  return [fontSizeNumber integerValue];
}

static NSString *const ColorSchemeKey = @"colorScheme";
static NSString *const FontFaceKey = @"fontFace";
static NSString *const FontSizeKey = @"fontSize";
static NSString *const MediaOverlaysEnableClick = @"mediaOverlaysEnableClick";

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
  NSURL *URL = [[NYPLBookContentMetadataFilesHelper currentAccountDirectory]
                URLByAppendingPathComponent:@"settings.json"];
  
  return URL;
}

- (void)load
{
  @synchronized(self) {
    NSData *const savedData = [NSData dataWithContentsOfURL:[self settingsURL]];
    if(!savedData) {
      self.colorScheme = NYPLReaderSettingsColorSchemeBlackOnWhite;
      self.fontFace = NYPLReaderSettingsFontFaceSerif;
      self.fontSize = NYPLReaderSettingsFontSizeNormal;
      
      if(UIAccessibilityIsVoiceOverRunning())
      {
         self.mediaOverlaysEnableClick = YES;
      }
      else {
         self.mediaOverlaysEnableClick = NO;
      }
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
    self.mediaOverlaysEnableClick = mediaOverlaysEnableClickToBOOL(dictionary[MediaOverlaysEnableClick]);
  }
}

- (NSDictionary *)dictionaryRepresentation
{
  NSDictionary *settings = @{ColorSchemeKey: colorSchemeToString(self.colorScheme),
                             FontFaceKey: fontFaceToString(self.fontFace),
                             FontSizeKey: fontSizeToString(self.fontSize),
                             MediaOverlaysEnableClick: mediaOverlaysEnableClickToString(self.mediaOverlaysEnableClick)};
  
  return settings;
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
    
    NSError *error = nil;
    if(![[NSFileManager defaultManager]
         replaceItemAtURL:[self settingsURL]
         withItemAtURL:[[self settingsURL] URLByAppendingPathExtension:@"temp"]
         backupItemName:nil
         options:NSFileManagerItemReplacementUsingNewMetadataOnly
         resultingItemURL:NULL
         error:&error]) {
      NYPLLOG(@"Failed to rename temporary settings file.");
      return;
    }
  }
}

- (void)setColorScheme:(NYPLReaderSettingsColorScheme const)colorScheme
{
  _colorScheme = colorScheme;

  __weak NYPLReaderSettings const *weakSelf = self;
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:NYPLReaderSettingsColorSchemeDidChangeNotification
     object:weakSelf];
  }];
}

- (void)setFontFace:(NYPLReaderSettingsFontFace const)fontFace
{
  _fontFace = fontFace;
  
  __weak NYPLReaderSettings const *weakSelf = self;
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:NYPLReaderSettingsFontFaceDidChangeNotification
     object:weakSelf];
  }];
}

- (void)setFontSize:(NYPLReaderSettingsFontSize const)fontSize
{
  _fontSize = fontSize;
  
  __weak NYPLReaderSettings const *weakSelf = self;
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:NYPLReaderSettingsFontSizeDidChangeNotification
     object:weakSelf];
  }];
}

-(void)setMediaOverlaysEnableClick:(NYPLReaderSettingsMediaOverlaysEnableClick)mediaOverlaysEnableClick {
    _mediaOverlaysEnableClick = mediaOverlaysEnableClick;
    __weak NYPLReaderSettings const *weakSelf = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      [[NSNotificationCenter defaultCenter]
       postNotificationName:NYPLReaderSettingsMediaClickOverlayAlwaysEnableDidChangeNotification
       object:weakSelf];
    }];
}

- (UIColor *)backgroundColor
{
  switch(self.colorScheme) {
    case NYPLReaderSettingsColorSchemeBlackOnSepia:
      return [NYPLConfiguration readerBackgroundSepiaColor];
    case NYPLReaderSettingsColorSchemeBlackOnWhite:
      return [NYPLConfiguration readerBackgroundColor];
    case NYPLReaderSettingsColorSchemeWhiteOnBlack:
    default:
      return [NYPLConfiguration readerBackgroundDarkColor];
  }
}

- (UIColor *)backgroundMediaOverlayHighlightColor
{
  switch(self.colorScheme) {
    case NYPLReaderSettingsColorSchemeBlackOnSepia:
      return [NYPLConfiguration backgroundMediaOverlayHighlightSepiaColor];
    case NYPLReaderSettingsColorSchemeBlackOnWhite:
      return [NYPLConfiguration backgroundMediaOverlayHighlightColor];
    case NYPLReaderSettingsColorSchemeWhiteOnBlack:
    default:
      return [NYPLConfiguration backgroundMediaOverlayHighlightDarkColor];
  }
}

- (UIColor *)foregroundColor
{
  switch(self.colorScheme) {
    case NYPLReaderSettingsColorSchemeBlackOnSepia:
    case NYPLReaderSettingsColorSchemeBlackOnWhite:
      return [UIColor blackColor];
    case NYPLReaderSettingsColorSchemeWhiteOnBlack:
    default:
      return [UIColor whiteColor];
  }
}

- (UIColor *)selectedForegroundColor
{
  switch(self.colorScheme) {
    case NYPLReaderSettingsColorSchemeBlackOnSepia:
    case NYPLReaderSettingsColorSchemeBlackOnWhite:
      return [UIColor whiteColor];
    case NYPLReaderSettingsColorSchemeWhiteOnBlack:
    default:
      return [UIColor blackColor];
  }
}

- (UIColor *)tintColor
{
  switch(self.colorScheme) {
    case NYPLReaderSettingsColorSchemeBlackOnSepia:
    case NYPLReaderSettingsColorSchemeBlackOnWhite:
      return [NYPLConfiguration mainColor];
    case NYPLReaderSettingsColorSchemeWhiteOnBlack:
    default:
      return [UIColor whiteColor];
  }
}

- (NSArray *)readiumStylesRepresentation
{
  NSString *fontFace;
  
  switch(self.fontFace) {
    case NYPLReaderSettingsFontFaceSans:
      fontFace = @"Helvetica";
      break;
    case NYPLReaderSettingsFontFaceSerif:
      fontFace = @"Georgia";
      break;
    case NYPLReaderSettingsFontFaceOpenDyslexic:
      fontFace = @"OpenDyslexic3";
      break;
  }
  
  return @[@{@"selector": @"*",
             @"declarations": @{@"color": [self.foregroundColor javascriptHexString],
                                @"font-family": fontFace,
                                @"-webkit-hyphens": @"auto"}}];
}

- (NSDictionary *)readiumSettingsRepresentation
{
  CGFloat const scalingFactor = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 1.1 : 1.5;
  
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
      baseSize = 120;
      break;
    case NYPLReaderSettingsFontSizeXLarge:
      baseSize = 150;
      break;
    case NYPLReaderSettingsFontSizeXXLarge:
      baseSize = 200;
      break;
    case NYPLReaderSettingsFontSizeXXXLarge:
      baseSize = 250;
      break;
  }

  return @{@"columnGap": @20,
           @"fontSize": @(baseSize * scalingFactor),
           @"syntheticSpread": @"auto",
           @"columnMaxWidth": @9999999,
           @"scroll": @NO,
           @"mediaOverlaysEnableClick": self.mediaOverlaysEnableClick ? @YES: @NO};
}

@end
