#import "NYPLReachability.h"

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
