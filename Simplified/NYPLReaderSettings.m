#import "NYPLReaderSettings.h"

@implementation NYPLReaderSettings

+ (NYPLReaderSettings *)sharedReaderSettings
{
  static dispatch_once_t predicate;
  static NYPLReaderSettings *sharedReaderSettings = nil;
  
  dispatch_once(&predicate, ^{
    sharedReaderSettings = [[self alloc] init];
    if(!sharedReaderSettings) {
      NYPLLOG(@"Failed to create shared reader settings.");
    }
  });
  
  return sharedReaderSettings;
}

@end
