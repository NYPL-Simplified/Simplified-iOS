@class NYPLCatalogUngroupedFeed;
@class NYPLRemoteViewController;
@class NYPLOpenSearchDescription;

#import "NYPLBookCellCollectionViewController.h"

@interface NYPLCatalogUngroupedFeedViewController : NYPLBookCellCollectionViewController

@property (nonatomic) NYPLOpenSearchDescription *searchDescription;
@property (nonatomic) NYPLCatalogUngroupedFeed *feed;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

// |remoteViewController| is weakly referenced.
- (instancetype)initWithUngroupedFeed:(NYPLCatalogUngroupedFeed *)feed
                 remoteViewController:(NYPLRemoteViewController *)remoteViewController;

@end
