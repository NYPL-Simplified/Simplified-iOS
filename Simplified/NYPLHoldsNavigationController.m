#import "NYPLHoldsViewController.h"

#import "NYPLHoldsNavigationController.h"
#import "NYPLSettings.h"
#import "NYPLAccount.h"
#import "NYPLBookRegistry.h"
#import "NYPLCatalogFeedViewController.h"
#import "NYPLConfiguration.h"
#import "NYPLRootTabBarController.h"
#import "NYPLCatalogNavigationController.h"


@implementation NYPLHoldsNavigationController

#pragma mark NSObject

- (instancetype)init
{
  NYPLHoldsViewController *holdsViewController = [[NYPLHoldsViewController alloc] init];
  self = [super initWithRootViewController:holdsViewController];
  if(!self) return nil;
  
  self.tabBarItem.image = [UIImage imageNamed:@"Holds"];
  [holdsViewController updateBadge];
  
  
  holdsViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                     initWithImage:[UIImage imageNamed:@"lib-icon"] style:(UIBarButtonItemStylePlain)
                                                     
                                                     target:self
                                                     action:@selector(switchLibrary)];
  holdsViewController.navigationItem.leftBarButtonItem.enabled = YES;
  
  NSString *library = [[NYPLSettings sharedSettings] currentLibrary];
  NSString *libraryName = @"New York Public Library";
  if ([library isEqualToString:@"0"])
  {
    libraryName = @"New York Public Library";
  }
  else if ([library isEqualToString:@"1"])
  {
    libraryName = @"Brooklyn Public Library";
  }
  else if ([library isEqualToString:@"2"])
  {
    libraryName = @"The Magic Library";
  }
  
  holdsViewController.navigationItem.title = libraryName;
  
  
  return self;
}

-(void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  NSString *library = [[NYPLSettings sharedSettings] currentLibrary];
  
  NSString *libraryName = @"New York Public Library";
  if ([library isEqualToString:@"0"])
  {
    libraryName = @"New York Public Library";
  }
  else if ([library isEqualToString:@"1"])
  {
    libraryName = @"Brooklyn Public Library";
  }
  else if ([library isEqualToString:@"2"])
  {
    libraryName = @"The Magic Library";
  }
  
  NYPLHoldsViewController *viewController = (NYPLHoldsViewController *)self.visibleViewController;
  
  viewController.navigationItem.title = libraryName;
  

}

- (void) switchLibrary
{
  NYPLHoldsViewController *viewController = (NYPLHoldsViewController *)self.visibleViewController;
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Pick Your Library" message:nil preferredStyle:(UIAlertControllerStyleActionSheet)];
  alert.popoverPresentationController.barButtonItem = viewController.navigationItem.leftBarButtonItem;
  alert.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
  
  [alert addAction:[UIAlertAction actionWithTitle:@"New York Public Library" style:(UIAlertActionStyleDefault) handler:^(__unused UIAlertAction *_Nonnull action) {
    
    
    [[NYPLSettings sharedSettings] setCurrentLibrary:@"0"];
    
    [NYPLAccount sharedAccount];
    [[NSNotificationCenter defaultCenter]
     postNotificationName:NYPLAccountDidChangeNotification
     object:nil];
    [[NYPLSettings sharedSettings] setCustomMainFeedURL:nil];
    
    
    [[NYPLBookRegistry sharedRegistry] justLoad];
    
    
    [self reloadSelected];
    
    
  }]];
  
  [alert addAction:[UIAlertAction actionWithTitle:@"Brooklyn Public Library" style:(UIAlertActionStyleDefault) handler:^(__unused UIAlertAction *_Nonnull  action) {
    
    
    [[NYPLSettings sharedSettings] setCurrentLibrary:@"1"];
    
    [NYPLAccount sharedAccount];
    [[NSNotificationCenter defaultCenter]
     postNotificationName:NYPLAccountDidChangeNotification
     object:nil];
    [[NYPLSettings sharedSettings] setCustomMainFeedURL:nil];
    
    [[NYPLBookRegistry sharedRegistry] justLoad];
    
    [self reloadSelected];
    
  }]];
  
  [alert addAction:[UIAlertAction actionWithTitle:@"The Magic Library" style:(UIAlertActionStyleDefault) handler:^(__unused UIAlertAction *_Nonnull  action) {
    
    
    [[NYPLSettings sharedSettings] setCurrentLibrary:@"2"];
    [NYPLAccount sharedAccount];
    [[NSNotificationCenter defaultCenter]
     postNotificationName:NYPLAccountDidChangeNotification
     object:nil];
    
    [[NYPLSettings sharedSettings] setCustomMainFeedURL:[NSURL URLWithString:@"http://oacontent.librarysimplified.org/"]];
    
    [[NYPLBookRegistry sharedRegistry] justLoad];
    
    [self reloadSelected];
    
  }]];
  
  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:(UIAlertActionStyleCancel) handler:nil]];
  
  [[NYPLRootTabBarController sharedController] safelyPresentViewController:alert animated:YES completion:nil];
  
}
- (void) reloadSelected {
  
  
  NYPLCatalogNavigationController * catalog = (NYPLCatalogNavigationController*)[NYPLRootTabBarController sharedController].viewControllers[0];
  
  [catalog reloadSelected];
  
  NSString *library = [[NYPLSettings sharedSettings] currentLibrary];
  
  NSString *libraryName = @"New York Public Library";
  if ([library isEqualToString:@"0"])
  {
    libraryName = @"New York Public Library";
  }
  else if ([library isEqualToString:@"1"])
  {
    libraryName = @"Brooklyn Public Library";
  }
  else if ([library isEqualToString:@"2"])
  {
    libraryName = @"The Magic Library";
  }
  
  NYPLHoldsViewController *viewController = (NYPLHoldsViewController *)self.visibleViewController;
  
  viewController.navigationItem.title = libraryName;
  
  
  
  
}

@end
