#import "AFNetworking.h"
#import "NYPLConfiguration.h"
#import "NYPLReachability.h"
#import "SimplyE-Swift.h"

@interface NYPLReachability ()

@property (nonatomic) NSURLSession *session;
@property (nonatomic) AFNetworkReachabilityManager *reachabilityManager;

@end

@implementation NYPLReachability

+ (NYPLReachability *)sharedReachability
{
  static NYPLReachability *sharedReachability;
  static dispatch_once_t onceToken;
  
  dispatch_once(&onceToken, ^{
    sharedReachability = [[self alloc] init];
  });
  
  return sharedReachability;
}

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.session = [NSURLSession sessionWithConfiguration:
                  [NSURLSessionConfiguration ephemeralSessionConfiguration]];
  
  self.reachabilityManager = [AFNetworkReachabilityManager managerForDomain:[NYPLConfiguration mainFeedURL].absoluteString];
  [self.reachabilityManager startMonitoring];
  
  [self.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
    switch (status) {
      case AFNetworkReachabilityStatusNotReachable:
        NYPLLOG(@"Network Reachability changed: No Internet Connection");
        break;
      case AFNetworkReachabilityStatusUnknown:
        NYPLLOG(@"Network Reachability changed: Unkown network status");
        break;
      default:
        [NetworkQueue retryQueue];
        NYPLLOG(@"Network Reachability changed: WIFI or 3G");
        break;
    }
  }];
  
  return self;
}

- (void)reachabilityForURL:(NSURL *const)URL
           timeoutInternal:(NSTimeInterval const)timeoutInternal
                   handler:(void (^ const)(BOOL reachable))handler
{
  NSMutableURLRequest *const request = [NSMutableURLRequest
                                        requestWithURL:URL
                                        cachePolicy:NSURLRequestReloadIgnoringCacheData
                                        timeoutInterval:timeoutInternal];
  
  request.HTTPMethod = @"HEAD";
  
  [[self.session
    dataTaskWithRequest:request
    completionHandler:^(__unused NSData *_Nullable data,
                        NSURLResponse * _Nullable response,
                        __unused NSError *_Nullable error)
    {
      handler(!!response);
    }]
   resume];
}

@end
