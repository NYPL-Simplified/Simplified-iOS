#import "NSDate+NYPLDateAdditions.h"

@implementation NSDate (NYPLDateAdditions)

+ (NSDate *)dateWithRFC3339:(NSString *)string
{
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  
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

@end
