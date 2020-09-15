@class NYPLCatalogSubsectionLink;

@interface NYPLCatalogLane : NSObject

@property (nonatomic, readonly) NSArray *books;
@property (nonatomic, readonly) NSURL *subsectionURL;
@property (nonatomic, readonly) NSString *title;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

// designated initializer
- (instancetype)initWithBooks:(NSArray *)books
                subsectionURL:(NSURL *)subsectionURL
                        title:(NSString *)title;

@end
