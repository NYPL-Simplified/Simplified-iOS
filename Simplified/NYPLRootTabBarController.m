#import "NYPLCatalogNavigationController.h"
#import "NYPLHoldsNavigationController.h"
#import "NYPLMyBooksNavigationController.h"
#import "NYPLMyBooksViewController.h"
#import "NYPLReaderViewController.h"
#import "NYPLSettings.h"
#import "NYPLSettingsSplitViewController.h"
#import "NYPLRootTabBarController.h"
#import "SimplyE-Swift.h"

@interface NYPLRootTabBarController () <UITabBarControllerDelegate>

@property (nonatomic) NYPLCatalogNavigationController *catalogNavigationController;
@property (nonatomic) NYPLMyBooksNavigationController *myBooksNavigationController;
@property (nonatomic) NYPLHoldsNavigationController *holdsNavigationController;
@property (nonatomic) NYPLSettingsSplitViewController *settingsSplitViewController;
@property (nonatomic) NSString *dismissedBookIdentifier;

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
                                               name:NYPLCurrentAccountDidChangeNotification
                                             object:nil];
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setTabViewControllers
{
  Account *const currentAccount = [AccountsManager shared].currentAccount;
  if (currentAccount.supportsReservations) {
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

/// Remove these some day if we can figure out why Readium stalls the entire app
/// when the user returns from a suspended or background state back to the foreground
/// while a book was left open.
- (void)dismissReaderViewControllerIfNeeded
{
  if(![self.selectedViewController isKindOfClass:[NYPLMyBooksNavigationController class]]) {
    NYPLLOG(@"Current selected view controller is not NYPLMyBooksNavigationController.");
    return;
  }

  NYPLMyBooksNavigationController *booksVC = (NYPLMyBooksNavigationController *)self.selectedViewController;
  if (![booksVC.topViewController isKindOfClass:[NYPLReaderViewController class]]) {
    NYPLLOG(@"Current VC in the navigation controller is not NYPLReaderViewController.");
    return;
  }

  NYPLReaderViewController *readerVC = (NYPLReaderViewController *)booksVC.topViewController;
  self.dismissedBookIdentifier = readerVC.bookIdentifier;
  [(NYPLMyBooksNavigationController *)self.selectedViewController popViewControllerAnimated:NO];
}

- (void)reapplyReaderViewControllerIfNeeded
{
  if (self.dismissedBookIdentifier) {
    NSString *bookID = self.dismissedBookIdentifier;
    self.dismissedBookIdentifier = nil;

    if(![self.selectedViewController isKindOfClass:[NYPLMyBooksNavigationController class]]) {
      NYPLLOG(@"Current selected view controller is not NYPLMyBooksNavigationController.");
      return;
    }

    NYPLMyBooksNavigationController *booksVC = (NYPLMyBooksNavigationController *)self.selectedViewController;
    if (![booksVC.topViewController isKindOfClass:[NYPLMyBooksViewController class]]) {
      NYPLLOG(@"Current VC in the navigation controller is not NYPLMyBooksViewController.");
      return;
    }

    NYPLReaderViewController *reappliedReaderVC = [[NYPLReaderViewController alloc] initWithBookIdentifier:bookID];
    [self pushViewController:reappliedReaderVC animated:NO];
  }
}

@end
