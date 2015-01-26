#import "NYPLConfiguration.h"

static NSString *const developmentFeedKey = @"NYPLConfigurationDevelopmentFeed";

@implementation NYPLConfiguration

+ (void)initialize
{
  [[UINavigationBar appearance]
   setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:17]}];
}

+ (NSURL *)mainFeedURL
{
  NSURL *const developmentURL = [self developmentFeedURL];
  
  if(developmentURL) return developmentURL;
  
  return [NSURL URLWithString:@"http://library-simplified.herokuapp.com"];
}

+ (NSURL *)developmentFeedURL
{
  return [[NSUserDefaults standardUserDefaults] URLForKey:developmentFeedKey];
}

+ (void)setDevelopmentFeedURL:(NSURL *const)URL
{
  [[NSUserDefaults standardUserDefaults] setURL:URL forKey:developmentFeedKey];
}

+ (NSURL *)loanURL
{
  return [NSURL URLWithString:@"http://library-simplified.herokuapp.com/loans"];
}

+ (UIColor *)mainColor
{
  return [UIColor colorWithRed:240/255.0 green:115/255.0 blue:31/255.0 alpha:1.0];
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

+ (NSString *)systemFontName
{
  return @"AvenirNext-Medium";
}

+ (NSString *)boldSystemFontName
{
  return @"AvenirNext-Bold";
}

@end
