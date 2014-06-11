@import Foundation;

@interface NYPLURLSetSession : NSObject

// designated initializer
// |handler| will be called with a dictionary containing the URLs as keys and NSData objects as
// values. If any errors occurred, an NSError object will be present where an NSData object would
// have otherwise been.
- (id)initWithURLSet:(NSSet *)urls
   completionHandler:(void (^)(NSDictionary *dataDictionary))handler;


@end
