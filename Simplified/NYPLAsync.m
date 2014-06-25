#import "NYPLAsync.h"

void NYPLAsyncFetch(NSURL *const url, void (^ handler)(NSData *data))
{
  [[[NSURLSession sharedSession]
    dataTaskWithRequest:[NSURLRequest requestWithURL:url]
    completionHandler:^(NSData *const data,
                        __attribute__((unused)) NSURLResponse *response,
                        NSError *const error) {
      if(error) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                       ^{handler(nil);});
      } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                       ^{handler(data);});
      }
    }]
   resume];
}

void NYPLAsyncFetchSet(NSSet *const set, void (^ handler)(NSDictionary *dataDictionary))
{
  if(!set.count) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{handler(@{});});
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
    NYPLAsyncFetch(url, ^(NSData *const data) {
      [lock lock];
      dataDictionary[url] = (data ? data : [NSNull null]);
      --remaining;
      if(!remaining) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                       ^{handler(dataDictionary);});
      }
      [lock unlock];
    });
  }
}
