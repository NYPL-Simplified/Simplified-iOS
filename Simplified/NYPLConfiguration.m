#import "NYPLConfiguration.h"

@implementation NYPLConfiguration

+ (NSURL *)mainFeedURL
{
  return [NSURL URLWithString:@"http://library-simplified.herokuapp.com"];
  // return [NSURL URLWithString:@"http://10.128.36.26:5000/lanes/eng"];
}

+ (UIColor *)mainColor
{
  return [UIColor colorWithRed:240/255.0 green:115/255.0 blue:31/255.0 alpha:1.0];
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
