#import "NYPLReaderContainerDelegate.h"
#import "NYPLLOG.h"

#if defined(FEATURE_DRM_CONNECTOR)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"
#pragma clang diagnostic ignored "-Wunused-parameter"
#pragma clang diagnostic ignored "-Wignored-qualifiers"
#pragma clang diagnostic ignored "-Wdelete-non-abstract-non-virtual-dtor"
#import <adept_filter.h>
#pragma clang diagnostic pop
#endif

@implementation NYPLReaderContainerDelegate

- (BOOL)container:(__attribute__((unused)) RDContainer *)container
   handleSdkError:(NSString * const)message
isSevereEpubError:(__unused const BOOL)isSevereEpubError
{
  [self log:message];

  // Ignore the error and continue.
  return YES;
}

#if defined(FEATURE_DRM_CONNECTOR)
- (void)containerRegisterContentFilters:(__attribute__((unused)) RDContainer *)container
{
  ePub3::AdeptFilter::Register();
}
#endif

@end
