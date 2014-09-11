@class NYPLCatalogSubsectionLink;

@interface NYPLCatalogLane : NSObject

@property (nonatomic, readonly) NSArray *books;
@property (nonatomic, readonly) NYPLCatalogSubsectionLink *subsectionLink;
@property (nonatomic, readonly) NSString *title;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

// designated initializer
- (instancetype)initWithBooks:(NSArray *)books
               subsectionLink:(NYPLCatalogSubsectionLink *)subsectionLink
                        title:(NSString *)title;

- (NSSet *)imageThumbnailURLs;

@end
