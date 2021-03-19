#import "NYPLLibraryNavigationController.h"

@interface NYPLHoldsNavigationController : NYPLLibraryNavigationController

- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithNavigationBarClass:(Class)navigationBarClass
                    toolbarClass:(Class)toolbarClass NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (id)initWithRootViewController:(UIViewController *)rootViewController NS_UNAVAILABLE;

// designated initializer
- (instancetype)init;

@end
