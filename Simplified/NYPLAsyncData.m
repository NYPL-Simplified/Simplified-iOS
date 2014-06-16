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

@end
