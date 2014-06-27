#import "NYPLConfiguration.h"

@implementation NYPLConfiguration

+ (NSURL *)mainFeedURL
{
  return [NSURL URLWithString:@"http://library-simplified.herokuapp.com"];
  // return [NSURL URLWithString:@"http://10.128.36.26:5000/lanes/eng"];
}

@end
