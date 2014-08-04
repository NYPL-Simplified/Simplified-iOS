@interface NYPLCatalogRoot : NSObject

@property (nonatomic, readonly) NSArray *lanes;
@property (nonatomic, readonly) NSURL *openSearchURL; // nilable

// In the callback, |root| will be |nil| if an error occurred.
+ (void)withURL:(NSURL *)URL handler:(void (^)(NYPLCatalogRoot *root))handler;

// designated initializer
- (instancetype)initWithLanes:(NSArray *)lanes
                openSearchURL:(NSURL *)openSearchURL;

@end
