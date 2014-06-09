#import "NYPLAllBooksNavigationController.h"

#import "NYPLRootTabBarController.h"

@interface NYPLRootTabBarController ()

@property (nonatomic) NYPLAllBooksNavigationController *allBooksViewController;

@end

@implementation NYPLRootTabBarController

#pragma mark NSObject

- (id)init
{
  self = [super init];
  if(!self) return nil;
  
  self.allBooksViewController = [[NYPLAllBooksNavigationController alloc] init];
  
  self.viewControllers = @[self.allBooksViewController];
  
  return self;
}

@end
