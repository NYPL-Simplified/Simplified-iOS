#import "NYPLReaderContainerDelegate.h"
#import "NYPLLOG.h"
#import "NYPLAccount.h"

#include <ePub3/MarlinContentModule.h>

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

- (void)containerRegisterContentFilters:(__attribute__((unused)) RDContainer *)container
{
#if defined(FEATURE_DRM_CONNECTOR)
  if([NYPLAccount sharedAccount].licensor[@"clientToken"]) {
    ePub3::AdeptFilter::Register();
  }
#endif
}

-(void)containerRegisterContentModules:(__attribute__((unused)) RDContainer *)container
{
  MarlinContentModule::Register();
}

@end
