@class NYPLOPDSFeed;
@class NYPLCatalogFacet;

@interface NYPLCatalogGroupedFeed : NSObject

@property (nonatomic, readonly) NSArray *lanes;
@property (nonatomic, readonly) NSURL *openSearchURL; // nilable
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSArray<NYPLCatalogFacet *> *entryPoints;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

// |feed.type| must be NYPLOPDSFeedTypeAcquisitionGrouped.
- (instancetype)initWithOPDSFeed:(NYPLOPDSFeed *)feed;

@end
