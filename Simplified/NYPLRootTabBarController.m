#import "NYPLCatalogNavigationController.h"
#import "NYPLMyBooksNavigationController.h"

#import "NYPLRootTabBarController.h"

@interface NYPLRootTabBarController ()

@property (nonatomic) NYPLCatalogNavigationController *catalogNavigationController;
@property (nonatomic) NYPLMyBooksNavigationController *myBooksNavigationController;

@end

@implementation NYPLRootTabBarController

#pragma mark NSObject

- (id)init
{
  self = [super init];
  if(!self) return nil;
  
  self.catalogNavigationController = [[NYPLCatalogNavigationController alloc] init];
  self.myBooksNavigationController = [[NYPLMyBooksNavigationController alloc] init];
  
  self.viewControllers = @[self.catalogNavigationController, self.myBooksNavigationController];
  
  return self;
}

@end
