@interface NYPLCatalogNavigationFeedViewController : UIViewController

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

// designated initializer
- (instancetype)initWithURL:(NSURL *)URL title:(NSString *)title;

@end
