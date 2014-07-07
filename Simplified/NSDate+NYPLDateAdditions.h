@interface NSDate (NYPLDateAdditions)

// This correctly parses fractional seconds, but ignores them due to |NSDate| limitations.
+ (instancetype)dateWithRFC3339:(NSString *)string;

- (NSDateComponents *)UTCComponents;

@end
