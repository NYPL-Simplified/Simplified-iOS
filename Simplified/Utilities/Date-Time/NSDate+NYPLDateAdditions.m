#import "NSDate+NYPLDateAdditions.h"

@implementation NSDate (NYPLDateAdditions)

+ (NSDate *)dateWithISO8601DateString:(NSString *const)string
{
  // sanity check
  if (string == nil) {
    return nil;
  }

  NSDate *date;
  NSISO8601DateFormatter *const ISODateFormatter = [[NSISO8601DateFormatter alloc] init];

  ISODateFormatter.formatOptions = NSISO8601DateFormatWithFullDate;
  ISODateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];

  date = [ISODateFormatter dateFromString:string];

  if(!date) {
    NSDateFormatter *const dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy";
    return [dateFormatter dateFromString:string];
  }

  return date;
}

- (NSDateComponents *)UTCComponents
{
  NSCalendar *const calendar = [[NSCalendar alloc]
                                initWithCalendarIdentifier:NSCalendarIdentifierISO8601];
  calendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
  
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wassign-enum"
  _Static_assert(sizeof(NSUInteger) == sizeof(NSCalendarUnit),
                 "NSCalenderUnit is not of the expected size.");
  return [calendar components:NSUIntegerMax fromDate:self];
#pragma clang diagnostic pop
}

@end
