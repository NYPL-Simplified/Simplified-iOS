@import Foundation;

@interface NSDate (NYPLDateAdditions)

/// Parses a ISO-8601 full date string with no time info.
/// @param string A ISO-8601 full date string, e.g. "2020-01-22".
/// @return A date if it was possible to parse the input string.
+ (nullable NSDate *)dateWithISO8601DateString:(nullable NSString *)string;

- (nonnull NSDateComponents *)UTCComponents;

@end
