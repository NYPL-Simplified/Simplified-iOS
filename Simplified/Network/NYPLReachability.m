#import "NYPLReachability.h"
#import "NYPLReachabilityManager.h"
#import "SimplyE-Swift.h"

@interface NYPLReachability ()

@property (nonatomic) NSURLSession *session;

@end

@implementation NYPLReachability

NSString *const NYPLReachabilityHostIsReachableNotification = @"NYPLReachabilityHostIsReachableNotification";

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
  
  self.hostReachabilityManager = [ReachabilityManager reachabilityWithHostName:@"www.apple.com"];
  [self.hostReachabilityManager startNotifier];
}

- (void)reachabilityChanged:(NSNotification *)note
{
  ReachabilityManager *currentReach = [note object];
  if (currentReach == self.hostReachabilityManager) {
    NetworkStatus netStatus = [self.hostReachabilityManager currentReachabilityStatus];
    switch (netStatus) {
      case ReachableViaWiFi:
      case ReachableViaWWAN:
        [[NSNotificationCenter defaultCenter] postNotificationName:NYPLReachabilityHostIsReachableNotification object:self];
        NYPLLOG(@"Host Reachability changed: WIFI or 3G");
        break;
      case NotReachable:
        NYPLLOG(@"Host Reachability changed: Not Reachable");
        break;
    }
  }
}

- (void)dealloc
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
