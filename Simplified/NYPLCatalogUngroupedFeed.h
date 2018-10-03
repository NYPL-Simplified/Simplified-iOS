@class NYPLCatalogUngroupedFeed;
@class NYPLOPDSFeed;
@class NYPLCatalogFacet;

@protocol NYPLCatalogUngroupedFeedDelegate

// Called only when existing books have been updated.
- (void)catalogUngroupedFeed:(NYPLCatalogUngroupedFeed *)catalogUngroupedFeed
              didUpdateBooks:(NSArray *)books;

// Called only when new books have been added.
- (void)catalogUngroupedFeed:(NYPLCatalogUngroupedFeed *)catalogUngroupedFeed
                 didAddBooks:(NSArray *)books
                       range:(NSRange)range;

@end

@interface NYPLCatalogUngroupedFeed : NSObject

@property (nonatomic, readonly) NSMutableArray *books;
@property (nonatomic, weak) id<NYPLCatalogUngroupedFeedDelegate> delegate; // nilable
@property (nonatomic, readonly) NSArray *facetGroups;
@property (nonatomic, readonly) NSURL *openSearchURL; // nilable
@property (nonatomic, readonly) NSString *searchTemplate; // nilable
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) BOOL currentlyFetchingNextURL;
@property (nonatomic, readonly) NSArray<NYPLCatalogFacet *> *entryPoints;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

// In the callback, |ungroupedFeed| will be |nil| if an error occurred.
+ (void)withURL:(NSURL *)URL handler:(void (^)(NYPLCatalogUngroupedFeed *ungroupedFeed))handler;

// |feed.type| must be NYPLOPDSFeedTypeAcquisitionUngrouped.
- (instancetype)initWithOPDSFeed:(NYPLOPDSFeed *)feed;

// This method is used to inform a catalog category that the data of a book at the given index is
// being used elsewhere. This knowledge allows preemptive retrieval of the next URL (if present) so
// that later books will be available upon request. It is important to have a delegate receive
// updates as it's the only way of knowing when data about new books has actually become available.
// It is an error to attempt to prepare for a book index equal to greater than |books.count|,
// something avoidable because book counts never decrease.
- (void)prepareForBookIndex:(NSUInteger)bookIndex;

@end
