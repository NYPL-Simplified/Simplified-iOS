#import "NYPLCatalogNavigationController.h"
#import "NYPLMyBooksNavigationController.h"
#import "NYPLHoldsNavigationController.h"
#import "NYPLSettingsNavigationController.h"

#import "NYPLRootTabBarController.h"

@interface NYPLRootTabBarController ()

@property (nonatomic) NYPLCatalogNavigationController *catalogNavigationController;
@property (nonatomic) NYPLMyBooksNavigationController *myBooksNavigationController;
@property (nonatomic) NYPLHoldsNavigationController *holdsNavigationController;
@property (nonatomic) NYPLSettingsNavigationController *settingsNavigationController;

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
  
  self.catalogNavigationController = [[NYPLCatalogNavigationController alloc] init];
  self.myBooksNavigationController = [[NYPLMyBooksNavigationController alloc] init];
  self.holdsNavigationController = [[NYPLHoldsNavigationController alloc] init];
  self.settingsNavigationController = [[NYPLSettingsNavigationController alloc] init];
  
  self.viewControllers = @[self.catalogNavigationController,
                           self.myBooksNavigationController,
                           self.holdsNavigationController,
                           self.settingsNavigationController];
  
  return self;
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

@end
