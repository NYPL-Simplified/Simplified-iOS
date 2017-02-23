#import "NYPLReaderContainerDelegate.h"
#import "NYPLLOG.h"
#include <ePub3/marlin_decrypter.h>

#if defined(FEATURE_DRM_CONNECTOR)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wno-all"
#import <adept_filter.h>
#pragma clang diagnostic pop
#endif

@implementation NYPLReaderContainerDelegate

- (BOOL)container:(__attribute__((unused)) RDContainer *)container
   handleSdkError:(NSString * const)message
isSevereEpubError:(__unused const BOOL)isSevereEpubError
{
  NYPLLOG(message);

  // Ignore the error and continue.
  return YES;
}

#if defined(FEATURE_DRM_CONNECTOR)
- (void)containerRegisterContentFilters:(__attribute__((unused)) RDContainer *)container
{
  //ePub3::AdeptFilter::Register();
  ePub3::MarlinDecrypter::Register();
}
#endif

@end
