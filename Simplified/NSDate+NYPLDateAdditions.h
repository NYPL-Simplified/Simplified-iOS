@import Foundation;

@interface NSDate (NYPLDateAdditions)

// This correctly parses fractional seconds, but ignores them due to |NSDate| limitations.
+ (NSDate *)dateWithRFC3339String:(NSString *)string;

/// Parses a ISO-8601 full date string with no time info.
/// @param string A ISO-8601 full date string, e.g. "2020-01-22".
/// @return A date if it was possible to parse the input string.
+ (NSDate *)dateWithISO8601DateString:(NSString *)string;

- (NSString *)RFC3339String;

- (NSString *)shortTimeUntilString;

- (NSString *)longTimeUntilString;

- (NSDateComponents *)UTCComponents;

@end
