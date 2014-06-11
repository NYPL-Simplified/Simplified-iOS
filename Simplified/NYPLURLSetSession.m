#import "NYPLURLSetSession.h"

@interface NYPLURLSetSession ()

@property (nonatomic, retain) NSURLSession *session;

@end

@implementation NYPLURLSetSession

- (id)initWithURLSet:(NSSet *const)urls
   completionHandler:(void (^)(NSDictionary *dataDictionary))handler
{
  self = [super init];
  if(!self) return nil;
  
  if(!urls || !handler) {
    @throw NSInvalidArgumentException;
  }
  
  NSURLSessionConfiguration *configuration =
    [NSURLSessionConfiguration ephemeralSessionConfiguration];
  
  configuration.HTTPMaximumConnectionsPerHost = 4;
  configuration.HTTPShouldUsePipelining = YES;
  
  // TODO: This should be handled more intelligently.
  self.session = [NSURLSession sessionWithConfiguration:configuration];
  
  NSLock *const lock = [[NSLock alloc] init];
  NSMutableDictionary *const results = [NSMutableDictionary dictionaryWithCapacity:[urls count]];
  __block NSUInteger tasksRemaining = [urls count];
  
  for(NSURL *const url in urls) {
    [[self.session
      dataTaskWithRequest:[NSURLRequest requestWithURL:url]
      completionHandler:^(NSData *const data,
                          __attribute__((unused)) NSURLResponse *response,
                          NSError *const error) {
        [lock lock];
        if(error) {
          [results setObject:error forKey:url];
        } else {
          [results setObject:data forKey:url];
        }
        --tasksRemaining;
        BOOL const done = !tasksRemaining;
        [lock unlock];
        
        if(done) {
          handler(results);
        }
      }]
     resume];
  }
  
  return self;
}

@end
