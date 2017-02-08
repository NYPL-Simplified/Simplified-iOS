#import "NYPLConfiguration.h"
#import "NYPLReachability.h"
#import "NYPLReachabilityManager.h"
#import "SimplyE-Swift.h"

@interface NYPLReachability ()

@property (nonatomic) NSURLSession *session;

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
  
  [self setupAppleReachability];
  
  return self;
}

- (void)setupAppleReachability
{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(reachabilityChanged:)
                                               name:kReachabilityChangedNotification
                                             object:nil];
  
  NSString *remoteHostName = [NYPLConfiguration mainFeedURL].absoluteString;
  
  self.hostReachabilityManager = [ReachabilityManager reachabilityWithHostName:remoteHostName];
  [self.hostReachabilityManager startNotifier];
}

/// Called by ReachabilityManager whenever status changes.
- (void) reachabilityChanged:(NSNotification *)note
{
  ReachabilityManager* curReach = [note object];
  if (curReach == self.hostReachabilityManager) {
    NetworkStatus netStatus = [self.hostReachabilityManager currentReachabilityStatus];
    switch (netStatus) {
      case ReachableViaWiFi:
      case ReachableViaWWAN:
        [NetworkQueue retryQueue];
        NYPLLOG(@"Host Reachability changed: WIFI or 3G");
        break;
      default:
        NYPLLOG(@"Host Reachability changed: Not Reachable");
        break;
    }
  }
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - NYPL

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
