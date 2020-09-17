@class NYPLOPDSFeed;

@interface NYPLCatalogFacetGroup : NSObject

@property (nonatomic, readonly) NSArray *facets;
@property (nonatomic, readonly) NSString *name;

- (instancetype)initWithFacets:(NSArray *)facets
                          name:(NSString *)name;

@end
