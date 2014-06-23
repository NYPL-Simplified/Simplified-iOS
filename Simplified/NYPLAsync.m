#import "NYPLAsync.h"

void NYPLAsyncDispatch(dispatch_block_t const block)
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

void NYPLAsyncFetch(NSURL *const url, void (^ handler)(NSData *data))
{
  [[[NSURLSession sharedSession]
    dataTaskWithRequest:[NSURLRequest requestWithURL:url]
    completionHandler:^(NSData *const data,
                        __attribute__((unused)) NSURLResponse *response,
                        NSError *const error) {
      if(error) {
        NYPLAsyncDispatch(^{handler(nil);});
      } else {
        NYPLAsyncDispatch(^{handler(data);});
      }
    }]
   resume];
}

void NYPLAsyncFetchSet(NSSet *const set, void (^ handler)(NSDictionary *dataDictionary))
{
  if(!set.count) {
    NYPLAsyncDispatch(^{handler(@{});});
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
        NYPLAsyncDispatch(^{handler(dataDictionary);});
      }
      [lock unlock];
    });
  }
}
