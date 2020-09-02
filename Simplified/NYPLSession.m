#import "NYPLAsync.h"
#import "SimplyE-Swift.h"

#import "NYPLSession.h"

@interface NYPLSession () <NSURLSessionDelegate, NSURLSessionTaskDelegate>

@property (nonatomic) NSURLSession *session;

@end

static NSUInteger const diskCacheInMegabytes = 20;
static NSUInteger const memoryCacheInMegabytes = 2;

static NYPLSession *sharedSession = nil;

@implementation NYPLSession

+ (instancetype)sharedSession
{
  static dispatch_once_t predicate;
  
  dispatch_once(&predicate, ^{
    sharedSession = [[self alloc] init];
    if(!sharedSession) {
      NYPLLOG(@"Failed to create shared session.");
    }
  });
  
  return sharedSession;
}

#pragma mark NSObject

- (instancetype)init
{
  if(sharedSession) {
    @throw NSGenericException;
  }
  
  self = [super init];
  if(!self) return nil;
  
  NSURLSessionConfiguration *const configuration =
    [NSURLSessionConfiguration defaultSessionConfiguration];
  
  assert(configuration.URLCache);
  
  configuration.URLCache.diskCapacity = 1024 * 1024 * diskCacheInMegabytes;
  configuration.URLCache.memoryCapacity = 1024 * 1024 * memoryCacheInMegabytes;
  
  self.session = [NSURLSession sessionWithConfiguration:configuration
                                               delegate:self
                                          delegateQueue:[NSOperationQueue mainQueue]];
  
  return self;
}

#pragma mark NSURLSessionTaskDelegate

- (void)URLSession:(__attribute__((unused)) NSURLSession *)session
              task:(__attribute__((unused)) NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *const)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                             NSURLCredential *credential))completionHandler
{
  NYPLLOG_F(@"NSURLSessionTask: %@. Challenge Received: %@",
            task.currentRequest.URL.absoluteString,
            challenge.protectionSpace.authenticationMethod);

    [NYPLBasicAuth authHandlerWithChallenge:challenge completionHandler:completionHandler];
}

#pragma mark -

- (void)uploadWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))handler
{
  [[self.session uploadTaskWithRequest:request
                              fromData:request.HTTPBody
                     completionHandler:handler] resume];
}

- (NSURLRequest*)withURL:(NSURL *const)URL
        shouldResetCache:(BOOL)shouldResetCache
       completionHandler:(void (^)(NSData *data,
                                   NSURLResponse *response,
                                   NSError *error))handler
{
  if(!handler) {
    @throw NSInvalidArgumentException;
  }

    NSURLRequest *req;
    void (^completionWrapper)(NSData * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable) = ^ void (NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error){
      if (error) {
        NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (dataString == nil) {
          dataString = [NSString stringWithFormat:@"datalength=%lu",
                        (unsigned long)data.length];
        }
        [NYPLErrorLogger logNetworkError:error
                                    code:NYPLErrorCodeApiCall
                                 summary:NSStringFromClass([self class])
                                 request:req
                                response:response
                                 message:@"NYPLSession error"
                                metadata:@{
                                  @"receivedData": dataString ?: @""
                                }];
        handler(nil, response, error);
        return;
      }

      handler(data, response, nil);
    };

  if (shouldResetCache) {
    // NB: this sledgehammer approach is not ideal, and the only reason we
    // don't use `removeCachedResponseForRequest:` (which is really what we
    // should be using) is because that method has been buggy since iOS 8,
    // and it still is in iOS 13.
    [NYPLNetworkExecutor.shared clearCache];
  }

  NSString *lpe = [URL lastPathComponent];
  if ([lpe isEqualToString:@"borrow"])
    req = [[NYPLNetworkExecutor.shared PUT:URL completion:completionWrapper] originalRequest];
  else
    req = [[NYPLNetworkExecutor.shared GET:URL cachePolicy:NSURLRequestUseProtocolCachePolicy completion:completionWrapper] originalRequest];

  return req;
}

@end
