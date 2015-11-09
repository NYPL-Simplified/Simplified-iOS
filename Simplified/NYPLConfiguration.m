#import "NYPLSettings.h"
#import "Heap.h"
#import "Bugsnag.h"
#import "HSHelpStack.h"
#import "HSZenDeskGear.h"

#if defined(FEATURE_DRM_CONNECTOR)
#import <ADEPT/ADEPT.h>
#endif

#import "NYPLConfiguration.h"
#import "UILabel+NYPLAppearanceAdditions.h"
#import "UIButton+NYPLAppearanceAdditions.h"

static NSString *const NYPLCirculationBaseURLProduction = @"https://circulation.librarysimplified.org";
static NSString *const NYPLCirculationBaseURLTesting = @"http://qa.circulation.librarysimplified.org/";
static NSString *const NYPLCirtulationBaseURLE_Feed = @"http://169.254.102.238/CANNOT_GENERATE_FEED_PROBLEM";

static NSString *const heapIDProduction = @"3245728259";
static NSString *const heapIDDevelopment = @"1848989408";

@implementation NYPLConfiguration

+ (void)initialize
{
  [[UINavigationBar appearance]
   setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:17]}];
  [[UILabel appearance] setFontName:[NYPLConfiguration systemFontName]];
  [[UIButton appearance] setTitleFontName:[NYPLConfiguration systemFontName]];
  
  [[HSHelpStack instance] setThemeFrompList:@"HelpStackTheme"];
  HSZenDeskGear *zenDeskGear  = [[HSZenDeskGear alloc]
                                 initWithInstanceUrl : @"https://nypl.zendesk.com"
                                 staffEmailAddress   : @"johannesneuer@nypl.org"
                                 apiToken            : @"P6aFczYFc4al6o2riRBogWLi5D0M0QCdrON6isJi"];
  
  HSHelpStack *helpStack = [HSHelpStack instance];
  helpStack.gear = zenDeskGear;
  
  if ([NYPLConfiguration heapEnabled]) {
    [Heap setAppId:[NYPLConfiguration heapID]];
#ifdef DEBUG
    [Heap enableVisualizer];
    //    [Heap startDebug];
#endif
  }
  
  if ([NYPLConfiguration bugsnagEnabled]) {
    [Bugsnag startBugsnagWithApiKey:[NYPLConfiguration bugsnagID]];
    [Bugsnag notify:[NSException exceptionWithName:@"ExceptionName" reason:@"Test Error" userInfo:nil]];
    s_logCallbackBlock = ^(NSString *loglevel, NSString *exceptionName, NSDictionary *data, NSString *message) {
      if (!exceptionName)
        exceptionName = @"NYPLGenericException";
      if (!loglevel)
        loglevel = @"warning";
      [Bugsnag notify:[NSException exceptionWithName:exceptionName reason:message userInfo:nil] withData:data atSeverity:loglevel];
    };
    [[NYPLADEPT sharedInstance] setLogCallback:^(NSString *logLevel,NSString *exceptionName, NSDictionary *data, NSString *message) {
      if (!exceptionName)
        exceptionName = @"NYPLADEPTException";
      [Bugsnag notify:[NSException exceptionWithName:exceptionName reason:message userInfo:nil] withData:data atSeverity:logLevel];
    }];
  }
}

+ (BOOL) heapEnabled
{
  return YES;
//  return NO;
}

+ (BOOL) bugsnagEnabled
{
  return YES;
  //  return NO;
}

+ (NSString *)heapID
{
//  return heapIDProduction;
  return heapIDDevelopment;
}

+ (NSString *) bugsnagID
{
  return @"725ae02b6ec60cad7d11beffdbd99d23";
}

+ (NSURL *)circulationURL
{
//    return [NSURL URLWithString:NYPLCirculationBaseURLTesting];
  return [NSURL URLWithString:NYPLCirculationBaseURLProduction];
//  return [NSURL URLWithString:NYPLCirtulationBaseURLE_Feed];
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
}

+ (NSURL *)registrationURL
{
//  return [NSURL URLWithString:@"https://simplifiedcard.herokuapp.com"];
  return [NSURL URLWithString:@"https://patrons.librarysimplified.org/"];
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

+ (NSString *)systemFontName
{
  return @"AvenirNext-Medium";
}

+ (NSString *)boldSystemFontName
{
  return @"AvenirNext-Bold";
}

@end
