#import "NYPLAsyncData.h"

@implementation NYPLAsyncData

+ (void)withURL:(NSURL *const)url
completionHandler:(void (^ const)(NSData *data))handler
{
  [[[NSURLSession sharedSession]
    dataTaskWithRequest:[NSURLRequest requestWithURL:url]
    completionHandler:^(NSData *const data,
                        __attribute__((unused)) NSURLResponse *response,
                        NSError *const error) {
      if(error) {
        NSLog(@"NYPLAsyncData: Error: %@", error.localizedDescription);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                       ^{handler(nil);});
      } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                       ^{handler(data);});
      }
    }]
   resume];
}

+ (void)withURLSet:(NSSet *)set
 completionHandler:(void (^)(NSDictionary *dataDictionary))handler
{
  if(!set.count) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{handler([NSDictionary dictionary]);});
    return;
  }
  
  for(id const object in set) {
    if(![object isKindOfClass:[NSURL class]]) {
      @throw NSInvalidArgumentException;
    }
  }
 
  NSLock *const lock = [[NSLock alloc] init];
  NSMutableDictionary *const dataDictionary = [NSMutableDictionary dictionary];
  __block NSUInteger remaining = set.count;
  
  for(NSURL *const url in set) {
    [NYPLAsyncData withURL:url completionHandler:^(NSData *const data) {
      [lock lock];
      [dataDictionary setObject:(data ? data : [NSNull null]) forKey:url];
      --remaining;
      if(!remaining) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                       ^{handler(dataDictionary);});
      }
      [lock unlock];
    }];
  }
}

@end
