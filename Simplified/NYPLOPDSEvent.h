@class NYPLOPDSEventHold;
@class NYPLOPDSEventLoan;
@class NYPLOPDSEventVisitor;

NS_ASSUME_NONNULL_BEGIN

@protocol NYPLOPDSEvent

- (void)matchHold:(void (^)(NYPLOPDSEventHold *))holdCase
        matchLoan:(void (^)(NYPLOPDSEventLoan *))loanCase;

@end

@interface NYPLOPDSEventHold : NSObject <NYPLOPDSEvent>

@property (nonatomic, readonly) NSDate *__nullable startDate;
@property (nonatomic, readonly) NSDate *__nullable endDate;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

- (instancetype)initWithStartDate:(nullable NSDate *)startDate
                          endDate:(nullable NSDate *)endDate;

@end

@interface NYPLOPDSEventLoan : NSObject <NYPLOPDSEvent>

@property (nonatomic, readonly) NSDate *__nullable startDate;
@property (nonatomic, readonly) NSDate *__nullable endDate;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

- (instancetype)initWithStartDate:(nullable NSDate *)startDate
                          endDate:(nullable NSDate *)endDate;

@end

NS_ASSUME_NONNULL_END