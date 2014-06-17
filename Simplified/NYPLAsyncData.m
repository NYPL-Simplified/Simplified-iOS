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
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          handler(nil);
        }];
      } else {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          handler(data);
        }];
      }
    }]
   resume];
}

+ (void)withURLSet:(NSSet *)set
 completionHandler:(void (^)(NSDictionary *dataDictionary))handler
{
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
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          handler(dataDictionary);
        }];
      }
      [lock unlock];
    }];
  }
}

@end
