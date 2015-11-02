#import "NYPLSettings.h"

#import "NYPLConfiguration.h"
#import "UILabel+NYPLAppearanceAdditions.h"
#import "UIButton+NYPLAppearanceAdditions.h"

static NSString *const NYPLCirculationBaseURLProduction = @"https://circulation.librarysimplified.org";
static NSString *const NYPLCirculationBaseURLTesting = @"http://qa.circulation.librarysimplified.org/";

static NSString *const heapIDProduction = @"3245728259";
static NSString *const heapIDDevelopment = @"1848989408";

@implementation NYPLConfiguration

+ (void)initialize
{
  [[UINavigationBar appearance]
   setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:17]}];
  [[UILabel appearance] setFontName:[NYPLConfiguration systemFontName]];
  [[UIButton appearance] setTitleFontName:[NYPLConfiguration systemFontName]];
}

+ (BOOL) heapEnabled
{
  return YES;
//  return NO;
}

+ (NSString *)heapID
{
//  return heapIDProduction;
  return heapIDDevelopment;
}

+ (NSURL *)circulationURL
{
//    return [NSURL URLWithString:NYPLCirculationBaseURLTesting];
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
