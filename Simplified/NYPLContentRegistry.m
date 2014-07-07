#import "NYPLContentRegistry.h"

@implementation NYPLContentRegistry

+ (NYPLContentRegistry *)sharedInstance
{
  static dispatch_once_t predicate;
  static NYPLContentRegistry *sharedContentRegistry = nil;
  
  dispatch_once(&predicate, ^{
    sharedContentRegistry = [[NYPLContentRegistry alloc] init];
    if(!sharedContentRegistry) {
      NYPLLOG(@"Failed to create shared content registry.");
    }
  });
  
  return sharedContentRegistry;
}

@end
