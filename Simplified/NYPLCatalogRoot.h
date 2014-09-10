@interface NYPLCatalogRoot : NSObject

@property (nonatomic, readonly) NSArray *lanes;
@property (nonatomic, readonly) NSString *searchTemplate; // nilable

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

// In the callback, |root| will be |nil| if an error occurred.
+ (void)withURL:(NSURL *)URL handler:(void (^)(NYPLCatalogRoot *root))handler;

// designated initializer
- (instancetype)initWithLanes:(NSArray *)lanes
               searchTemplate:(NSString *)searchTemplate;

@end
