@import Foundation;

@interface NYPLMyBooksSimplifiedBearerToken : NSObject

@property (nonatomic, readonly, nonnull) NSString *accessToken;
@property (nonatomic, readonly, nonnull) NSDate *expiration;
@property (nonatomic, readonly, nonnull) NSURL *location;

+ (instancetype _Null_unspecified)new NS_UNAVAILABLE;
- (instancetype _Null_unspecified)init NS_UNAVAILABLE;

- (instancetype _Nonnull)initWithAccessToken:(NSString *_Nonnull)accessToken
                                  expiration:(NSDate *_Nonnull)expiration
                                    location:(NSURL *_Nonnull)location
  NS_DESIGNATED_INITIALIZER;

/// @param dictionary The result of parsing the JSON from the server.
/// @return A Simplified bearer token representation if the input is valid,
/// else @c nil.
+ (instancetype _Nullable)simplifiedBearerTokenWithDictionary:(NSDictionary *_Nonnull)dictionary;

@end
