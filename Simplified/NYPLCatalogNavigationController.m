#import "NYPLCatalogFeedViewController.h"

#import "NYPLCatalogNavigationController.h"

#import "NYPLAccount.h"
#import "NYPLBookRegistry.h"
#import "NYPLRootTabBarController.h"
#import "NYPLMyBooksNavigationController.h"
#import "NYPLMyBooksViewController.h"
#import "NYPLHoldsNavigationController.h"
#import "SimplyE-Swift.h"
#import "NSString+NYPLStringAdditions.h"

#if defined(FEATURE_DRM_CONNECTOR)
#import <ADEPT/ADEPT.h>
#endif

@implementation NYPLCatalogNavigationController

/// Replaces the current view controllers on the navigation stack with a single
/// view controller pointed at the current catalog URL.
- (void)loadTopLevelCatalogViewController
{
  if (![NSThread isMainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self loadTopLevelCatalogViewControllerInternal];
    });
  } else {
    [self loadTopLevelCatalogViewControllerInternal];
  }
}

- (void)loadTopLevelCatalogViewControllerInternal
{
  self.viewController = [[NYPLCatalogFeedViewController alloc] initWithURL:[NYPLSettings sharedSettings].accountMainFeedURL];
  
  self.viewController.title = NSLocalizedString(@"Catalog", nil);
  self.viewController.navigationItem.title = [AccountsManager shared].currentAccount.name;
  self.viewController.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Catalog", nil) style:UIBarButtonItemStylePlain target:nil action:nil];
  self.viewControllers = @[self.viewController];
}

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  
  self.tabBarItem.title = NSLocalizedString(@"Catalog", nil);
  self.tabBarItem.image = [UIImage imageNamed:@"Catalog"];
  
  [self loadTopLevelCatalogViewController];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentAccountChanged) name:NSNotification.NYPLCurrentAccountDidChange object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncBegan) name:NSNotification.NYPLSyncBegan object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncEnded) name:NSNotification.NYPLSyncEnded object:nil];
  
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)currentAccountChanged
{
  [self loadTopLevelCatalogViewController];
}

- (void)syncBegan
{
  self.navigationItem.leftBarButtonItem.enabled = NO;
  self.viewController.navigationItem.leftBarButtonItem.enabled = NO;
}

- (void)syncEnded
{
  self.navigationItem.leftBarButtonItem.enabled = YES;
  self.viewController.navigationItem.leftBarButtonItem.enabled = YES;
}

- (void)updateFeedAndRegistryOnAccountChange
{
  Account *account = [[AccountsManager sharedInstance] currentAccount];
  __block NSURL *mainFeedUrl = [NSURL URLWithString:account.catalogUrl];
  void (^completion)(void) = ^() {
    [[NYPLSettings sharedSettings] setAccountMainFeedURL:mainFeedUrl];
    [UIApplication sharedApplication].delegate.window.tintColor = [NYPLConfiguration shared].mainColor;
    
    [[NYPLBookRegistry sharedRegistry] justLoad];
    [[NYPLBookRegistry sharedRegistry] syncWithCompletionHandler:^(BOOL __unused success) {
      if (success) {
        [[NYPLBookRegistry sharedRegistry] save];
      }
    }];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:NSNotification.NYPLCurrentAccountDidChange
     object:nil];
  };
  if (account.details.needsAgeCheck) {
    [[AgeCheck shared] verifyCurrentAccountAgeRequirement:^(BOOL isOfAge) {
      dispatch_async(dispatch_get_main_queue(), ^{
        mainFeedUrl = isOfAge ? account.details.coppaOverUrl : account.details.coppaUnderUrl;
        completion();
      });
    }];
  } else {
    if (![NSThread isMainThread]) {
      dispatch_async(dispatch_get_main_queue(), ^{
        completion();
      });
    } else {
      completion();
    }
  }
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  NYPLSettings *settings = [NYPLSettings sharedSettings];
  Account *account = [[AccountsManager sharedInstance] currentAccount];

  __block NSURL *mainFeedUrl = [NSURL URLWithString:account.catalogUrl];
  void (^completion)(void) = ^() {
    [[NYPLSettings sharedSettings] setAccountMainFeedURL:mainFeedUrl];
    [UIApplication sharedApplication].delegate.window.tintColor = [NYPLConfiguration shared].mainColor;

    [[NSNotificationCenter defaultCenter]
    postNotificationName:NSNotification.NYPLCurrentAccountDidChange
    object:nil];
  };

  if (account.details.needsAgeCheck) {
    [[AgeCheck shared] verifyCurrentAccountAgeRequirement:^(BOOL isOfAge) {
      dispatch_async(dispatch_get_main_queue(), ^{
        mainFeedUrl = isOfAge ? account.details.coppaOverUrl : account.details.coppaUnderUrl;
        completion();
      });
    }];
  } else {
    completion();
  }
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
  if (UIAccessibilityIsVoiceOverRunning()) {
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
  }
}

@end
