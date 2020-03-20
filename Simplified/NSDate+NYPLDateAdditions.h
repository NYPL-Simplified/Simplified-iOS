@interface NSDate (NYPLDateAdditions)

// This correctly parses fractional seconds, but ignores them due to |NSDate| limitations.
+ (NSDate *)dateWithRFC3339String:(NSString *)string;

+ (NSDate *)dateWithISO8601DateString:(NSString *)string;

- (NSString *)RFC3339String;

- (NSString *)shortTimeUntilString;

- (NSString *)longTimeUntilString;

- (NSDateComponents *)UTCComponents;

/**
 * Gets the current date and time, formatted properly (according to RFC 1123)
 * for insertion into an HTTP header.
 */
- (NSString *)RFC1123String;

@end
