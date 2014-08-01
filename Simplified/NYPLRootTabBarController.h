@interface NYPLRootTabBarController : UITabBarController

+ (instancetype)sharedController;

// This method will present a view controller from the receiver, or from the controller currently
// being presented from the receiver, or from the controller being presented by that one, and so on,
// such that no duplicate presenting errors occur.
- (void)safelyPresentViewController:(UIViewController *)viewController
                           animated:(BOOL)animated
                         completion:(void (^)(void))completion;

@end
