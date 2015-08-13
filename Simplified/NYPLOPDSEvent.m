#import "NSDate+NYPLDateAdditions.h"
#import "NYPLNull.h"

#import "NYPLOPDSEvent.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const NameKey = @"name";
static NSString *const PositionKey = @"position";
static NSString *const StartDateKey = @"startDate";
static NSString *const EndDateKey = @"endDate";

@interface NYPLOPDSEvent ()

@property (nonatomic) NSString *__nonnull name;
@property (nonatomic) NSInteger position;
@property (nonatomic) NSDate *__nullable startDate;
@property (nonatomic) NSDate *__nullable endDate;

@end

@implementation NYPLOPDSEvent

- (instancetype)initWithName:(NSString * __nonnull)name
                   startDate:(nullable NSDate *)startDate
                     endDate:(nullable NSDate *)endDate
                    position:(NSInteger)position
{
  self = [super init];
  if(!self) return nil;
  
  self.name = name;
  self.position = position;
  self.startDate = startDate;
  self.endDate = endDate;
  
  return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
  self = [super init];
  if (!self || !dictionary) return nil;
  self.name = dictionary[NameKey];
  self.position = [dictionary[PositionKey] integerValue];
  self.startDate = [NSDate dateWithRFC3339String:NYPLNullToNil(dictionary[StartDateKey])];
  self.endDate = [NSDate dateWithRFC3339String:NYPLNullToNil(dictionary[EndDateKey])];
  
  return self;
}

- (NSDictionary *)dictionaryRepresentation
{
  return @{NameKey: self.name,
           PositionKey: @(self.position),
           StartDateKey: NYPLNullFromNil([self.startDate RFC3339String]),
           EndDateKey: NYPLNullFromNil([self.endDate RFC3339String])
           };
}

- (void)matchHold:(void (^)())holdCase
        matchLoan:(void (^)())loanCase
{
  if ([self.name isEqualToString:@"hold"]) {
    holdCase();
  } else {
    loanCase();
  }
}


@end

NS_ASSUME_NONNULL_END