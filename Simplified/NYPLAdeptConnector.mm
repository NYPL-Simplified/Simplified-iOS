#pragma clang diagnostic push
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

#import "NYPLAdeptConnector.h"

@implementation NYPLAdeptConnector

+ (NYPLAdeptConnector *)sharedAdeptConnector
{
  static dispatch_once_t predicate;
  static NYPLAdeptConnector *sharedAdeptConnector = nil;
  
  dispatch_once(&predicate, ^{
    sharedAdeptConnector = [[self alloc] init];
    if(!sharedAdeptConnector) {
      NYPLLOG(@"Failed to create shared Adept connector.");
    }
  });
  
  return sharedAdeptConnector;
}

@end
