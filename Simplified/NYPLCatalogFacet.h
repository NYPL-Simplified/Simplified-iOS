@class NYPLOPDSLink;

@interface NYPLCatalogFacet : NSObject

@property (nonatomic, readonly) BOOL active;
@property (nonatomic, readonly) NSURL *href;
@property (nonatomic, readonly) NSString *title; // nilable

// The link provided must have the |NYPLOPDSRelationFacet| relation.
+ (NYPLCatalogFacet *)catalogFacetWithLink:(NYPLOPDSLink *)link;

- (instancetype)initWithActive:(BOOL)active
                          href:(NSURL *)href
                         title:(NSString *)title;

@end
