#import "NYPLConfiguration.h"

@implementation NYPLConfiguration

+ (NSURL *)mainFeedURL
{
  return [NSURL URLWithString:@"http://johnnowak.com/nypl/Navigation.eng.xml"];
}

@end
