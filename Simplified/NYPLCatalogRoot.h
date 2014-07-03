@interface NYPLCatalogRoot : NSObject

@property (nonatomic, readonly) NSArray *lanes;

// In the callback, |root| will be |nil| if an error occurred.
+ (void)withURL:(NSURL *)URL handler:(void (^)(NYPLCatalogRoot *root))handler;

// designated initializer
- (instancetype)initWithLanes:(NSArray *)lanes;

@end
