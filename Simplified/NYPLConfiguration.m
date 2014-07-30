#import "NYPLConfiguration.h"

@implementation NYPLConfiguration

+ (NSURL *)mainFeedURL
{
  return [NSURL URLWithString:@"http://library-simplified.herokuapp.com"];
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

+ (NSString *)systemFontName
{
  return @"AvenirNext-Medium";
}

+ (NSString *)boldSystemFontName
{
  return @"AvenirNext-Bold";
}

@end
