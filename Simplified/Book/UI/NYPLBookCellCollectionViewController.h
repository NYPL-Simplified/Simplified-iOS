// This class exists to factor out commonalities of various view controllers that show book cells
// via a collection view. It sets up a collection view and handles updating of book cells, but it
// does *not* implement UICollectionViewDataSource and UICollectionViewDelegate methods. Subclasses
// of this class should set the relevant properties of the collection view appropriately to handle
// their unique needs.

@class NYPLReauthenticator;

@interface NYPLBookCellCollectionViewController : UIViewController

@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) NYPLReauthenticator *reauthenticator;

- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

// Called whenever the book registry issues notifications, thus triggering a reload of the
// collection view. Subclasses should do whatever they need to do here *before* the view is
// reloaded, e.g. recalculating the order in which cells should later be provided.
- (void)willReloadCollectionViewData;

@end
