@interface NYPLCatalogCategory : NSObject

@property (nonatomic, readonly) NSArray *books;
@property (nonatomic, readonly) NSURL *nextURL; // nilable
@property (nonatomic, readonly) NSString *title;

// In the callback, |root| will be |nil| if an error occurred.
+ (void)withURL:(NSURL *)url handler:(void (^)(NYPLCatalogCategory *category))handler;

// designated initializer
- (instancetype)initWithBooks:(NSArray *)books
                      nextURL:(NSURL *)nextURL
                        title:(NSString *)title;

@end
