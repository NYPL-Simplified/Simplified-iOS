#import "NYPLSettings.h"
#import "Bugsnag.h"
#import "HSHelpStack.h"
#import "HSDeskGear.h"

#if defined(FEATURE_DRM_CONNECTOR)
#import <ADEPT/ADEPT.h>
#endif

#import "NYPLConfiguration.h"
#import "UILabel+NYPLAppearanceAdditions.h"
#import "UIButton+NYPLAppearanceAdditions.h"

//static NSString *const NYPLCirculationBaseURLProduction = @"http://api.deslibris.ca/api/opds?criteria=f_subject:HIS006000";
static NSString *const NYPLCirculationBaseURLProduction = @"https://circulation.librarysimplified.org";
static NSString *const NYPLCirculationBaseURLTesting = @"http://qa.circulation.librarysimplified.org/";

static NSString *const heapIDProduction = @"3245728259";
static NSString *const heapIDDevelopment = @"1848989408";

@implementation NYPLConfiguration

+ (void)initialize
{
  [[HSHelpStack instance] setThemeFrompList:@"HelpStackTheme"];
  HSDeskGear *deskGear = [[HSDeskGear alloc]
                          initWithInstanceBaseUrl:@"https://nypl.desk.com/"
                          toHelpEmail:@"jamesenglish@nypl.org"
                          staffLoginEmail:@"jamesenglish@nypl.org"
                          AndStaffLoginPassword:@"Marin1010!"];
  HSHelpStack *helpStack = [HSHelpStack instance];
  helpStack.gear = deskGear;
  
  
  if([NYPLConfiguration bugsnagEnabled]) {
    [Bugsnag startBugsnagWithApiKey:[NYPLConfiguration bugsnagID]];
  }
  
#if defined(FEATURE_DRM_CONNECTOR)
  [[NYPLADEPT sharedInstance] setLogCallback:^(__unused NSString *logLevel,
                                               NSString *const exceptionName,
                                               __unused NSDictionary *data,
                                               NSString *const message) {
    NSLog(@"ADEPT: %@: %@", exceptionName, message);
  }];
#endif
}

+ (BOOL) heapEnabled
{
  return !TARGET_OS_SIMULATOR;
}

+ (BOOL) bugsnagEnabled
{
  return !TARGET_OS_SIMULATOR;
}

+ (NSString *)heapID
{
//  return heapIDProduction;
  return heapIDDevelopment;
}

+ (NSString *) bugsnagID
{
  return @"76cb0080ae8cc30d903663e10b138381";
}

+ (NSURL *)circulationURL
{
  return [NSURL URLWithString:NYPLCirculationBaseURLProduction];
}

+ (NSURL *)mainFeedURL
{
  NSURL *const customURL = [NYPLSettings sharedSettings].customMainFeedURL;

  if(customURL) return customURL;
  
  return [self circulationURL];
}

+ (NSURL *)loanURL
{
  return [[self circulationURL] URLByAppendingPathComponent:@"loans"];
  //return [NSURL URLWithString:@"http://api.deslibris.ca/api/opds?action=GetShelf"];
}

+ (BOOL)cardCreationEnabled
{
  //Card Creator functionality is currently disabled until a later date.
  return NO;
}

+ (NSURL *)registrationURL
{
//  return [NSURL URLWithString:@"https://simplifiedcard.herokuapp.com"];
  return [NSURL URLWithString:@"https://patrons.librarysimplified.org/"];
}

+ (NSURL *)minimumVersionURL
{
  return [NSURL URLWithString:@"http://www.librarysimplified.org/simplye-client/minimum-version"];
}

+ (UIColor *)mainColor
{
  return [UIColor colorWithRed:220/255.0 green:34/255.0 blue:29/255.0 alpha:1.0];
}

+ (UIColor *)accentColor
{
  return [UIColor colorWithRed:0.0/255.0 green:144/255.0 blue:196/255.0 alpha:1.0];
}

+ (UIColor *)backgroundColor
{
  return [UIColor colorWithWhite:250/255.0 alpha:1.0];
}

+ (UIColor *)backgroundDarkColor
{
  return [UIColor colorWithWhite:5/255.0 alpha:1.0];
}

+ (UIColor *)backgroundSepiaColor
{
  return [UIColor colorWithRed:242/255.0 green:228/255.0 blue:203/255.0 alpha:1.0];
}

+(UIColor *)backgroundMediaOverlayHighlightColor {
  return [UIColor yellowColor];
}

+(UIColor *)backgroundMediaOverlayHighlightDarkColor {
  return [UIColor orangeColor];
}

+(UIColor *)backgroundMediaOverlayHighlightSepiaColor {
  return [UIColor yellowColor];
}

// Set for the whole app via UIView+NYPLFontAdditions.
+ (NSString *)systemFontName
{
  return @"AvenirNext-Medium";
}

// Set for the whole app via UIView+NYPLFontAdditions.
+ (NSString *)boldSystemFontName
{
  return @"AvenirNext-Bold";
}

@end
