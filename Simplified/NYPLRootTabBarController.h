@class NYPLCatalogNavigationController;
@class NYPLMyBooksNavigationController;
@class NYPLHoldsNavigationController;
@class NYPLSettingsSplitViewController;

@interface NYPLRootTabBarController : UITabBarController

@property (nonatomic) NYPLCatalogNavigationController *catalogNavigationController;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

+ (instancetype)sharedController;

/// This method will present a view controller from the receiver, or from the
/// controller currently being presented from the receiver, or from the
/// controller being presented by that one, and so on, such that no duplicate
/// presenting errors occur.
- (void)safelyPresentViewController:(UIViewController *)viewController
                           animated:(BOOL)animated
                         completion:(void (^)(void))completion;

/// Pushes a view controller onto the navigation controller currently selected
/// by the underlying tab bar controller.
- (void)pushViewController:(UIViewController *const)viewController
                  animated:(BOOL const)animated;

- (void)setCatalogNavController:(NYPLCatalogNavigationController*)controller;
- (void)setMyBooksNavController:(NYPLMyBooksNavigationController*)controller;
- (void)setHoldsNavController:(NYPLHoldsNavigationController*)controller;
- (void)setSettingsSplitViewController:(UISplitViewController*)controller;

@end
