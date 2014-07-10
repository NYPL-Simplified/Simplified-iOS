#import "NSDate+NYPLDateAdditions.h"

@implementation NSDate (NYPLDateAdditions)

+ (NSDate *)dateWithRFC3339String:(NSString *const)string
{
  NSDateFormatter *const dateFormatter = [[NSDateFormatter alloc] init];
  
  dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
  dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ssX5";
  dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
  
  NSDate *const date = [dateFormatter dateFromString:string];
  
  if(!date) {
    dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSSSSX5";
    return [dateFormatter dateFromString:string];
  }
  
  return date;
}

- (NSString *)RFC3339String
{
  NSDateFormatter *const dateFormatter = [[NSDateFormatter alloc] init];
  
  dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
  dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
  dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
  
  return [dateFormatter stringFromDate:self];
}

- (NSDateComponents *)UTCComponents
{
  NSCalendar *const calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSISO8601Calendar];
  calendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
  
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wassign-enum"
  _Static_assert(sizeof(NSUInteger) == sizeof(NSCalendarUnit),
                 "NSCalenderUnit is not of the expected size.");
  return [calendar components:NSUIntegerMax fromDate:self];
#pragma clang diagnostic pop
}

@end
