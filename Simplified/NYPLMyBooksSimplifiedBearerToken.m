#import "NYPLMyBooksSimplifiedBearerToken.h"

@interface NYPLMyBooksSimplifiedBearerToken ()

@property (nonatomic, nonnull) NSString *accessToken;
@property (nonatomic, nonnull) NSDate *expiration;
@property (nonatomic, nonnull) NSURL *location;

@end

@implementation NYPLMyBooksSimplifiedBearerToken

- (instancetype _Nonnull)initWithAccessToken:(NSString *const _Nonnull)accessToken
                                  expiration:(NSDate *const _Nonnull)expiration
                                    location:(NSURL *const _Nonnull)location
{
  self = [super init];

  self.accessToken = accessToken;
  self.expiration = expiration;
  self.location = location;

  return self;
}

+ (instancetype _Nullable)simplifiedBearerTokenWithDictionary:(NSDictionary *const _Nonnull)dictionary
{
  NSString *const locationString = dictionary[@"location"];
  if (![locationString isKindOfClass:[NSString class]]) {
    return nil;
  }

  NSURL *const location = [NSURL URLWithString:locationString];
  if (!location) {
    return nil;
  }

  NSString *const accessToken = dictionary[@"access_token"];
  if (![accessToken isKindOfClass:[NSString class]]) {
    return nil;
  }

  NSString *const expirationNumber = dictionary[@"expiration"];

  NSInteger const expirationSeconds = expirationNumber ? [expirationNumber integerValue] : 0;

  NSDate *const expiration =
    (expirationSeconds > 0
     ? [NSDate dateWithTimeIntervalSinceNow:expirationSeconds]
     : [NSDate distantFuture]);

  return [[self alloc] initWithAccessToken:accessToken expiration:expiration location:location];
}

@end
