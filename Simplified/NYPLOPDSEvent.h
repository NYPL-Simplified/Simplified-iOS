@class NYPLOPDSEventVisitor;

NS_ASSUME_NONNULL_BEGIN

@interface NYPLOPDSEvent : NSObject

- (void)matchHold:(void (^)(NYPLOPDSEvent *))holdCase
        matchLoan:(void (^)(NYPLOPDSEvent *))loanCase;

@property (nonatomic, readonly) NSString *__nonnull name;
@property (nonatomic, readonly) NSInteger position;
@property (nonatomic, readonly) NSDate *__nullable startDate;
@property (nonatomic, readonly) NSDate *__nullable endDate;

- (instancetype)initWithName:(nonnull NSString *)name
                   startDate:(nullable NSDate *)startDate
                     endDate:(nullable NSDate *)endDate
                    position:(NSInteger)position;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)dictionaryRepresentation;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END