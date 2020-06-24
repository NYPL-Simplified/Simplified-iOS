@interface NSDate (NYPLDateAdditions)

// This correctly parses fractional seconds, but ignores them due to |NSDate| limitations.
+ (nullable NSDate *)dateWithRFC3339String:(nullable NSString *)string;

+ (nullable NSDate *)dateWithISO8601DateString:(nullable NSString *)string;

- (nonnull NSString *)RFC3339String;

- (nonnull NSString *)shortTimeUntilString;

- (nonnull NSString *)longTimeUntilString;

- (nonnull NSDateComponents *)UTCComponents;

@end
