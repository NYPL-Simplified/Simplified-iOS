#import "NYPLCatalogNavigationController.h"

#import "NYPLRootTabBarController.h"

@interface NYPLRootTabBarController ()

@property (nonatomic) NYPLCatalogNavigationController *allBooksViewController;

@end

@implementation NYPLRootTabBarController

#pragma mark NSObject

- (id)init
{
  self = [super init];
  if(!self) return nil;
  
  self.allBooksViewController = [[NYPLCatalogNavigationController alloc] init];
  
  self.viewControllers = @[self.allBooksViewController];
  
  return self;
}

@end
