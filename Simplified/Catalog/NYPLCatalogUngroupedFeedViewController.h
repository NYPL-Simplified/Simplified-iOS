@class NYPLCatalogUngroupedFeed;
@class NYPLRemoteViewController;

#import "NYPLBookCellCollectionViewController.h"

/// This VC handles the presentation of vertical list of books, such as
/// My Books, Holds, and a single lane of the catalog presented by itself
/// in a vertically scrolling list.
@interface NYPLCatalogUngroupedFeedViewController : NYPLBookCellCollectionViewController

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

// |remoteViewController| is weakly referenced.
- (instancetype)initWithUngroupedFeed:(NYPLCatalogUngroupedFeed *)feed
                 remoteViewController:(NYPLRemoteViewController *)remoteViewController;

@end
