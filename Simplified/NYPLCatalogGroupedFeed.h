@class NYPLOPDSFeed;

@interface NYPLCatalogGroupedFeed : NSObject

@property (nonatomic, readonly) NSArray *lanes;
@property (nonatomic, readonly) NSString *searchTemplate; // nilable
@property (nonatomic, readonly) NSString *title;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

// |feed.type| must be NYPLOPDSFeedTypeAcquisitionGrouped.
- (instancetype)initWithOPDSFeed:(NYPLOPDSFeed *)feed;

@end
