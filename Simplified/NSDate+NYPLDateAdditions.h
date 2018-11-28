@interface NSDate (NYPLDateAdditions)

// This correctly parses fractional seconds, but ignores them due to |NSDate| limitations.
+ (NSDate *)dateWithRFC3339String:(NSString *)string;

+ (NSDate *)dateWithISO8601DateString:(NSString *)string;

+ (BOOL)isTimeOneDayLeft:(NSDate *)date;

- (NSString *)RFC3339String;

- (NSString *)shortTimeUntilString;

- (NSString *)longTimeUntilString;

- (NSDateComponents *)UTCComponents;

@end
