#import "NYPLCatalogNavigationController.h"
#import "NYPLHoldsNavigationController.h"
#import "NYPLMyBooksNavigationController.h"
#import "NYPLMyBooksViewController.h"
#import "NYPLReaderViewController.h"

#ifdef SIMPLYE
// TODO: SIMPLY-3053 this #ifdef can be removed once this ticket is done
#import "NYPLSettingsSplitViewController.h"
#endif

#import "NYPLRootTabBarController.h"
#import "SimplyE-Swift.h"

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

  [self setTabViewControllers];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(setTabViewControllers)
                                               name:NSNotification.NYPLCurrentAccountDidChange
                                             object:nil];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(dismissReaderUponEnteringBackground)
                                               name:UIApplicationDidEnterBackgroundNotification
                                             object:nil];
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setTabViewControllers
{
  [NYPLMainThreadRun asyncIfNeeded:^{
    [self setTabViewControllersInternal];
  }];
}

- (void)setTabViewControllersInternal
{
  Account *const currentAccount = [AccountsManager shared].currentAccount;
  if (currentAccount.details.supportsReservations) {
    self.viewControllers = @[self.catalogNavigationController,
                             self.myBooksNavigationController,
                             self.holdsNavigationController,
                             self.settingsSplitViewController];
  } else {
    self.viewControllers = @[self.catalogNavigationController,
                             self.myBooksNavigationController,
                             self.settingsSplitViewController];
    [self setSelectedIndex:0];
  }
}

#pragma mark - UITabBarControllerDelegate

- (BOOL)tabBarController:(UITabBarController *)__unused tabBarController
shouldSelectViewController:(nonnull UIViewController *)viewController
{
  if ([viewController isEqual:self.settingsSplitViewController] && [self.selectedViewController isEqual:self.settingsSplitViewController]) {
    UINavigationController *navController = [[(UISplitViewController *)viewController viewControllers] firstObject];
    [navController popToRootViewControllerAnimated:YES];
  }
  return YES;
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

#pragma mark -

/// Dismiss NYPLReaderViewController if entering the background, to try and
/// mitigate reported issue of the app freezing and not allowing navigation. Can
/// be removed whenever the renderer is replaced.
/// https://jira.nypl.org/browse/SIMPLY-1298
- (void)dismissReaderUponEnteringBackground
{
  if (![self.selectedViewController isKindOfClass:[UINavigationController class]]) {
    return;
  }
  UINavigationController *selectedTab = (UINavigationController *)self.selectedViewController;
  if (![selectedTab.topViewController isKindOfClass:[NYPLReaderViewController class]]) {
    NYPLLOG(@"Entering Background: Ignoring VC that is not NYPLReaderViewController.");
    return;
  }

  [selectedTab popViewControllerAnimated:NO];
}

@end
