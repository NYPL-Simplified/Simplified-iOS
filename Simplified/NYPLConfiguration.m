#import "NYPLSettings.h"

#import "NYPLConfiguration.h"

static NSString *const NYPLCirculationBaseURLProduction = @"http://qa.circulation.librarysimplified.org";
static NSString *const NYPLCirculationBaseURLTesting = @"http://circulation.alpha.librarysimplified.org";

@implementation NYPLConfiguration

+ (void)initialize
{
  [[UINavigationBar appearance]
   setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:17]}];
}

+ (NSURL *)circulationURL
{
    return [NSURL URLWithString:NYPLCirculationBaseURLTesting];
}

+ (NSURL *)mainFeedURL
{
    NSURL *const customURL = [NYPLSettings sharedSettings].customMainFeedURL;

    if(customURL) return customURL;

    return [[self circulationURL] URLByAppendingPathComponent:@"groups"];
}

+ (NSURL *)loanURL
{
    return [[self circulationURL] URLByAppendingPathComponent:@"loans"];
}

+ (NSURL *)registrationURL
{
  return [NSURL URLWithString:@"https://simplifiedcard.herokuapp.com"];
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
