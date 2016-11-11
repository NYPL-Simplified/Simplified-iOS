#import "NYPLMyBooksViewController.h"

#import "NYPLMyBooksNavigationController.h"
#import "NYPLSettings.h"
#import "NYPLAccount.h"
#import "NYPLBookRegistry.h"
#import "NYPLCatalogFeedViewController.h"
#import "NYPLConfiguration.h"
#import "NYPLRootTabBarController.h"
#import "NYPLCatalogNavigationController.h"
#import "SimplyE-Swift.h"


@implementation NYPLMyBooksNavigationController

#pragma mark NSObject

- (instancetype)init
{
  NYPLMyBooksViewController *viewController =
  [[NYPLMyBooksViewController alloc] init];
  
  self = [super initWithRootViewController:viewController];
  if(!self) return nil;
  
  self.tabBarItem.image = [UIImage imageNamed:@"MyBooks"];
  
  
  viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                     initWithImage:[UIImage imageNamed:@"lib-icon"] style:(UIBarButtonItemStylePlain)
                                                     
                                                     target:self
                                                     action:@selector(switchLibrary)];
  viewController.navigationItem.leftBarButtonItem.enabled = YES;


  
  return self;
}

-(void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
    
  NYPLMyBooksViewController *viewController = (NYPLMyBooksViewController *)self.visibleViewController;
  
  viewController.navigationItem.title = [[NYPLSettings sharedSettings] currentAccount].name;
    
}

- (void) switchLibrary
{
  NYPLMyBooksViewController *viewController = (NYPLMyBooksViewController *)self.visibleViewController;
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Pick Your Library" message:nil preferredStyle:(UIAlertControllerStyleActionSheet)];
  alert.popoverPresentationController.barButtonItem = viewController.navigationItem.leftBarButtonItem;
  alert.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
  
  [alert addAction:[UIAlertAction actionWithTitle:@"New York Public Library" style:(UIAlertActionStyleDefault) handler:^(__unused UIAlertAction *_Nonnull action) {
    
    [[NYPLSettings sharedSettings] setCurrentAccountIdentifier:NYPLUserAccountTypeNYPL];
    
    [self reloadSelected];

    
  }]];
  
  [alert addAction:[UIAlertAction actionWithTitle:@"Brooklyn Public Library" style:(UIAlertActionStyleDefault) handler:^(__unused UIAlertAction *_Nonnull  action) {
    
    
    [[NYPLSettings sharedSettings] setCurrentAccountIdentifier:NYPLUserAccountTypeBrooklyn];
    
    [self reloadSelected];
    
  }]];
  
  [alert addAction:[UIAlertAction actionWithTitle:@"Instant Classics" style:(UIAlertActionStyleDefault) handler:^(__unused UIAlertAction *_Nonnull  action) {
    
    [[NYPLSettings sharedSettings] setCurrentAccountIdentifier:NYPLUserAccountTypeMagic];

    [self reloadSelected];
    
  }]];
  
  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:(UIAlertActionStyleCancel) handler:nil]];
  
  [[NYPLRootTabBarController sharedController] safelyPresentViewController:alert animated:YES completion:nil];
  
}

- (void) reloadSelected {
  
  [NYPLAccount sharedAccount];
  
  Account *account = [[NYPLSettings sharedSettings] currentAccount];
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLAccountDidChangeNotification
   object:nil];
  
  [[NYPLSettings sharedSettings] setAccountMainFeedURL:[NSURL URLWithString:account.catalogUrl]];
  [UIApplication sharedApplication].delegate.window.tintColor = [NYPLConfiguration mainColor];
  
  [[NYPLBookRegistry sharedRegistry] justLoad];

  
  NYPLCatalogNavigationController * catalog = (NYPLCatalogNavigationController*)[NYPLRootTabBarController sharedController].viewControllers[0];
  
  [catalog reloadSelected];
  
  
  NYPLMyBooksViewController *viewController = (NYPLMyBooksViewController *)self.visibleViewController;
  
  viewController.navigationItem.title =  [[NYPLSettings sharedSettings] currentAccount].name;
  
}

@end
