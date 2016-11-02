#import "NYPLCatalogNavigationController.h"
#import "NYPLHoldsNavigationController.h"
#import "NYPLMyBooksNavigationController.h"
#import "NYPLSettingsSplitViewController.h"

#import "NYPLRootTabBarController.h"

@interface NYPLRootTabBarController () <UITabBarControllerDelegate>

@property (nonatomic) NYPLCatalogNavigationController *catalogNavigationController;
@property (nonatomic) NYPLMyBooksNavigationController *myBooksNavigationController;
@property (nonatomic) NYPLHoldsNavigationController *holdsNavigationController;
@property (nonatomic) NYPLSettingsSplitViewController *settingsSplitViewController;

@end

@implementation NYPLRootTabBarController

+ (instancetype)sharedController
{
  static dispatch_once_t predicate;
  static NYPLRootTabBarController *sharedController = nil;
  
  dispatch_once(&predicate, ^{
    sharedController = [[self alloc] init];
    if(!sharedController) {
      NYPLLOG(@"Failed to create shared controller.");
    }
  });
  
  return sharedController;
}

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.delegate = self;
  
  self.catalogNavigationController = [[NYPLCatalogNavigationController alloc] init];
  self.myBooksNavigationController = [[NYPLMyBooksNavigationController alloc] init];
  self.holdsNavigationController = [[NYPLHoldsNavigationController alloc] init];
  self.settingsSplitViewController = [[NYPLSettingsSplitViewController alloc] init];
  
  self.viewControllers = @[self.catalogNavigationController,
                           self.myBooksNavigationController,
                           self.holdsNavigationController,
                           self.settingsSplitViewController];
  
  return self;
}

#pragma mark - UITabBarControllerDelegate

- (void)tabBarController:(UITabBarController *)tabBarController
 didSelectViewController:(UIViewController *)viewController
{
  if ([viewController isEqual:self.settingsSplitViewController]) {
    UINavigationController *navController = [[(UISplitViewController *)viewController viewControllers] firstObject];
    [navController popToRootViewControllerAnimated:YES];
  }
}

#pragma mark -

- (void)safelyPresentViewController:(UIViewController *)viewController
                           animated:(BOOL)animated
                         completion:(void (^)(void))completion
{
  UIViewController *baseController = self;
  
  while(baseController.presentedViewController) {
    baseController = baseController.presentedViewController;
  }
  
  [baseController presentViewController:viewController animated:animated completion:completion];
}

- (void)pushViewController:(UIViewController *const)viewController
                  animated:(BOOL const)animated
{
  if(![self.selectedViewController isKindOfClass:[UINavigationController class]]) {
    NYPLLOG(@"Selected view controller is not a navigation controller.");
    return;
  }
  
  if(self.presentedViewController) {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
  
  [(UINavigationController *)self.selectedViewController
   pushViewController:viewController
   animated:animated];
}

@end
