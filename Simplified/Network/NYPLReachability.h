@import Foundation;

@class ReachabilityManager;

@interface NYPLReachability : NSObject

+ (NYPLReachability *)sharedReachability;

/// Performs a HEAD request to the @c URL in question and reports back whether or not
/// the server responded via @c handler.
///
/// @param URL The URL for which to check reachability.
/// @param timeoutInternal The maximum time to wait in seconds.
/// @param handler The handler to which the reachability of the URL will be reported.

- (void)reachabilityForURL:(NSURL *)URL
           timeoutInternal:(NSTimeInterval)timeoutInternal
                   handler:(void (^)(BOOL reachable))handler;

@property (nonatomic) ReachabilityManager *hostReachabilityManager;

extern NSString *const NYPLReachabilityHostIsReachableNotification;

@end
