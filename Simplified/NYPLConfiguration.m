#import "NYPLConfiguration.h"

@implementation NYPLConfiguration

+ (NSURL *)mainFeedURL
{
  return [NSURL URLWithString:@"http://library-simplified.herokuapp.com"];
}

@end
