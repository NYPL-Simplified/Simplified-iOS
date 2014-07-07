@interface NSDate (NYPLDateAdditions)

// This correctly parses fractional seconds, but ignores them due to |NSDate| limitations.
+ (instancetype)dateWithRFC3339String:(NSString *)string;

- (NSString *)RFC3339String;

- (NSDateComponents *)UTCComponents;

@end
