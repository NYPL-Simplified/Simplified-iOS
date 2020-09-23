@interface NSDate (NYPLDateAdditions)

// This correctly parses fractional seconds, but ignores them due to |NSDate| limitations.
+ (nullable NSDate *)dateWithRFC3339String:(nullable NSString *)string;

/// Parses a ISO-8601 full date string with no time info.
/// @param string A ISO-8601 full date string, e.g. "2020-01-22".
/// @return A date if it was possible to parse the input string.
+ (nullable NSDate *)dateWithISO8601DateString:(nullable NSString *)string;

- (nonnull NSString *)RFC3339String;

- (nonnull NSString *)shortTimeUntilString;

- (nonnull NSString *)longTimeUntilString;

- (nonnull NSDateComponents *)UTCComponents;

@end
