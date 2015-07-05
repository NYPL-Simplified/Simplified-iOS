@class NYPLCatalogGroupedFeed;

@interface NYPLCatalogGroupedFeedViewController : UIViewController

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

- (instancetype)initWithGroupedFeed:(NYPLCatalogGroupedFeed *)feed;

@end
