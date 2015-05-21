@interface NYPLAdeptConnectorOperation : NSObject

@property (nonatomic, readonly) void (^block)();

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (instancetype)operationWithBlock:(void (^)())block;

- (instancetype)initWithBlock:(void (^)())block;

@end