@interface NYPLBookCoverRegistry : NSObject

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (NYPLBookCoverRegistry *)sharedRegistry;

@end
