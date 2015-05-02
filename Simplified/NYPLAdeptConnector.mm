#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wweak-vtables"

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
#include <ePub3/curlnetprovider.h>
#include <ePub3/DRMWrapper.h>
#include <ePub3/connectorHelperFns.h>
#include <ePub3/launcherResProvider.h>
#pragma clang diagnostic pop

#import "NYPLLOG.h"

#import "NYPLAdeptConnector.h"

class DRMProcessorClient : public dpdrm::DRMProcessorClient
{
public:
  DRMProcessorClient()
  {

  }
  
  virtual void workflowsDone(unsigned int const workflows,
                             __attribute__((unused)) const dp::Data &followUp)
  {
    NSLog(@"XXX: Completed workflows: %d", workflows);
  }

  virtual void requestPasshash(__attribute__((unused))
                               const dp::ref<dpdrm::FulfillmentItem> &fulfillmentItem)
  {
    NSLog(@"NYPLAdeptConnector: Ignoring unsupported passhash request.");
  }

  virtual void requestInput(__attribute__((unused)) const dp::Data &inputXHTML)
  {
    NSLog(@"NYPLAdeptConnector: Ignoring unexpected input request.");
  }
  
  virtual void requestConfirmation(__attribute__((unused)) const dp::String &code)
  {
    NSLog(@"NYPLAdeptConnector: Ignoring unexpected confirmation request.");
  }

  virtual void reportWorkflowProgress(unsigned int const workflow,
                                      const dp::String &title,
                                      double const progress)
  {
    NSLog(@"XXX: Workflow progress: %d, %@, %f",
          workflow,
          [NSString stringWithUTF8String:title.utf8()],
          progress);
  }
  
  virtual void reportWorkflowError(unsigned int const workflow,
                                   const dp::String &errorCode)
  {
    NSLog(@"XXX: Workflow error: %d, %@",
          workflow,
          [NSString stringWithUTF8String:errorCode.utf8()]);
  }
  
  virtual void reportFollowUpURL(__attribute__((unused)) unsigned int const workflow,
                                 __attribute__((unused)) const dp::String &url)
  {
    NSLog(@"NYPLAdeptConnector: Ignoring unimplemented join accounts follow-up.");
  }
  
  virtual void reportDownloadCompleted(const dp::ref<dpdrm::FulfillmentItem> &fulfillmentItem,
                                       const dp::String &url)
  {
    NSLog(@"XXX: Download completed: %@, %@",
          [NSString stringWithUTF8String:fulfillmentItem->getDownloadMethod().utf8()],
          [NSString stringWithUTF8String:url.utf8()]);
  }
};

@interface NYPLAdeptConnector ()

@property (nonatomic) LauncherResProvider *launcherResProvider;
@property (nonatomic) dpdrm::DRMProcessor *processor;
@property (nonatomic) DRMProcessorClient *processorClient;

@end

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

#pragma mark NSObject

+ (void)initialize
{
  dpnet::NetProvider::setProvider(new NETPROVIDERIMPL(false));
  
  LauncherResProvider *const launcherResProvider =
    new LauncherResProvider(dp::String([[NSString stringWithFormat:@"file://%@/",
                                         [[NSBundle mainBundle] bundlePath]]
                                        UTF8String]),
                            true);
  dpres::ResourceProvider::setProvider(launcherResProvider);
  
  dp::platformInit(dp::PI_DEFAULT);
  
  dp::setVersionInfo("product", "SDKLauncher");
  dp::setVersionInfo("clientVersion", "SDKLauncher 1.0");
  dp::setVersionInfo("hobbes", "11.0.1");
  dp::setVersionInfo("connectorOnly", "true");
  
  dp::cryptRegisterOpenSSL();
  dp::deviceRegisterPrimary();
  dp::deviceRegisterExternal();
}

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.processorClient = new DRMProcessorClient();
  
  dpdev::DeviceProvider *const deviceProvider = dpdev::DeviceProvider::getProvider(0);
  dpdev::Device *const device = deviceProvider->getDevice(0);
  self.processor =
    dpdrm::DRMProvider::getProvider()->createDRMProcessor(self.processorClient, device);
  
  return self;
}

- (void)dealloc
{
  self.processor->release();
  delete self.processorClient;
}

#pragma mark -

- (BOOL)isDeviceAuthorized
{
  return !!self.processor->getActivations().length();
}

@end

#pragma clang diagnostic pop
