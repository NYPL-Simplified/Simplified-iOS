#import "NYPLMyBooksViewController.h"

#import "NYPLMyBooksNavigationController.h"
#import "NYPLAccount.h"
#import "NYPLBookRegistry.h"
#import "NYPLCatalogFeedViewController.h"
#import "NYPLRootTabBarController.h"
#import "NYPLCatalogNavigationController.h"
#import "SimplyE-Swift.h"

#if defined(FEATURE_DRM_CONNECTOR)
#import <ADEPT/ADEPT.h>
#endif

@implementation NYPLMyBooksNavigationController

#pragma mark NSObject

- (instancetype)init
{
  NYPLMyBooksViewController *viewController = [[NYPLMyBooksViewController alloc] init];
  
  self = [super initWithRootViewController:viewController];
  if (!self) return nil;
  
  self.tabBarItem.image = [UIImage imageNamed:@"MyBooks"];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentAccountChanged) name:NSNotification.NYPLCurrentAccountDidChange object:nil];
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
    
  NYPLMyBooksViewController *viewController = (NYPLMyBooksViewController *)self.visibleViewController;
  
  viewController.navigationItem.title = [AccountsManager shared].currentAccount.name;
    
}

- (void)currentAccountChanged
{
  if (![NSThread isMainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self popToRootViewControllerAnimated:NO];
    });
  } else {
    [self popToRootViewControllerAnimated:NO];
  }
}

@end
