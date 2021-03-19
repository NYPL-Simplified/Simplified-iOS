#import "NSDate+NYPLDateAdditions.h"

@implementation NSDate (NYPLDateAdditions)

+ (NSDate *)dateWithRFC3339String:(NSString *const)string
{
  // sanity check
  if (string == nil) {
    return nil;
  }

  static NSDateFormatter *dateFormatter;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
  });

  dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ssX5";
  NSDate *const date = [dateFormatter dateFromString:string];
  
  if(!date) {
    dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSSSSX5";
    return [dateFormatter dateFromString:string];
  }
  
  return date;
}

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

- (NSString *)RFC3339String
{
  static NSDateFormatter *dateFormatter;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
  });

  return [dateFormatter stringFromDate:self];
}

- (NSString *)shortTimeUntilString
{
  return [self timeUntilStringWithNames:@{@"year": @"y",
                                          @"month": @"m",
                                          @"week": @"w",
                                          @"day": @"d",
                                          @"hour": @"h",
                                          } appendPlural:@""];
}

// FIXME: These strings need to be localized and pluralization needs to be handled properly.
- (NSString *)longTimeUntilString
{
  return [self timeUntilStringWithNames:@{@"year": @" year",
                                          @"month": @" month",
                                          @"week": @" week",
                                          @"day": @" day",
                                          @"hour": @" hour"
                                          } appendPlural:@"s"];
}

- (NSString *)timeUntilStringWithNames:(NSDictionary *)names appendPlural:(NSString *)appendPlural
{
  NSTimeInterval seconds = [self timeIntervalSinceDate:[NSDate date]];
  seconds = MAX(seconds, 0);
  long minutes = seconds / 60;
  long hours = minutes / 60;
  long days = hours / 24;
  long weeks = days / 7;
  long months = days / 30;
  long years = days / 365;
  
  if(years >= 4) {
    // Switch to years after ~48 months.
    return [NSString stringWithFormat:@"%ld%@%@", years, names[@"year"], years != 1 ? appendPlural : @""];
  } else if(months >= 4) {
    // Switch to months after ~16 weeks.
    return [NSString stringWithFormat:@"%ld%@%@", months, names[@"month"], months != 1 ? appendPlural : @""];
  } else if(weeks >= 4) {
    // Switch to weeks after 28 days.
    return [NSString stringWithFormat:@"%ld%@%@", weeks, names[@"week"], weeks != 1 ? appendPlural : @""];
  } else if(days >= 2) {
    // Switch to days after 48 hours.
    return [NSString stringWithFormat:@"%ld%@%@", days, names[@"day"], days != 1 ? appendPlural : @""];
  } else {
    // Use hours.
    return [NSString stringWithFormat:@"%ld%@%@", hours, names[@"hour"], hours != 1 ? appendPlural : @""];
  }
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
