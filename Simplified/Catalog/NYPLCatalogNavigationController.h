// Despite the name, this class has nothing to do with OPDS navigation feeds. It's simply the
// UINavigationController for the catalog portion of the application.

#import "NYPLLibraryNavigationController.h"

@interface NYPLCatalogNavigationController : NYPLLibraryNavigationController

- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithNavigationBarClass:(Class)navigationBarClass
                    toolbarClass:(Class)toolbarClass NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (id)initWithRootViewController:(UIViewController *)rootViewController NS_UNAVAILABLE;

// designated initializer
- (instancetype)init;

- (void)updateFeedAndRegistryOnAccountChange;

- (void)loadTopLevelCatalogViewController;

@end
