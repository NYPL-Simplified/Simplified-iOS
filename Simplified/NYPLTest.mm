#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wc++98-compat"
#pragma clang diagnostic ignored "-Wc++98-compat-pedantic"
#pragma clang diagnostic ignored "-Wcast-align"
#pragma clang diagnostic ignored "-Wdeprecated"
#pragma clang diagnostic ignored "-Wextra-semi"
#pragma clang diagnostic ignored "-Wglobal-constructors"
#pragma clang diagnostic ignored "-Wold-style-cast"
#pragma clang diagnostic ignored "-Wpadded"
#pragma clang diagnostic ignored "-Wreorder"
#pragma clang diagnostic ignored "-Wundef"
#pragma clang diagnostic ignored "-Wunused-parameter"
#pragma clang diagnostic ignored "-Wweak-vtables"
#include <ePub3/DRMWrapper.h>
#pragma clang diagnostic pop

#import "NYPLLOG.h"

#import "NYPLTest.h"

@implementation NYPLTest

+ (NYPLTest *)sharedTest
{
  static dispatch_once_t predicate;
  static NYPLTest *sharedTest;
  
  dispatch_once(&predicate, ^{
    sharedTest = [[self alloc] init];
    if(!sharedTest) {
      NYPLLOG(@"Failed to create shared test.");
    }
  });
  
  return sharedTest;
}

- (void)test
{
  NSLog(@"Testing...");
  
  getWrapperObj().AuthorizeDevice("AdobeID", "johnnowak@nypl.org", "oaFytiVQDlHU82WN");
}

@end
