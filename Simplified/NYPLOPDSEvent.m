#import "NYPLOPDSEvent.h"

NS_ASSUME_NONNULL_BEGIN

@interface NYPLOPDSEventHold ()

@property (nonatomic) NSDate *__nullable startDate;
@property (nonatomic) NSDate *__nullable endDate;

@end

@implementation NYPLOPDSEventHold

- (instancetype)initWithStartDate:(nullable NSDate *const)startDate
                          endDate:(nullable NSDate *const)endDate
{
  self = [super init];
  if(!self) return nil;
  
  self.startDate = startDate;
  self.endDate = endDate;
  
  return self;
}

#pragma mark NYPLOPDSEvent

- (void)matchHold:(void (^)(NYPLOPDSEventHold *const))holdCase
        matchLoan:(__attribute__((unused)) void (^)(NYPLOPDSEventLoan *const))loanCase
{
  holdCase(self);
}

@end

@interface NYPLOPDSEventLoan ()

@property (nonatomic) NSDate *__nullable startDate;
@property (nonatomic) NSDate *__nullable endDate;

@end

@implementation NYPLOPDSEventLoan

- (instancetype)initWithStartDate:(nullable NSDate *const)startDate
                          endDate:(nullable NSDate *const)endDate
{
  self = [super init];
  if(!self) return nil;
  
  self.startDate = startDate;
  self.endDate = endDate;
  
  return self;
}

#pragma mark NYPLOPDSEvent

- (void)matchHold:(__attribute__((unused)) void (^)(NYPLOPDSEventHold *const))holdCase
        matchLoan:(void (^)(NYPLOPDSEventLoan *const))loanCase
{
  loanCase(self);
}

@end

NS_ASSUME_NONNULL_END