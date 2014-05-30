#import "NYPLAllBooksViewController.h"

#import "NYPLRootTabBarController.h"

@interface NYPLRootTabBarController ()

@property (nonatomic, retain) NYPLAllBooksViewController *allBooksViewController;

@end

@implementation NYPLRootTabBarController

#pragma mark NSObject

- (id)init
{
  self = [super init];
  if(!self) return nil;
  
  self.allBooksViewController = [[NYPLAllBooksViewController alloc] init];
  
  self.viewControllers = @[self.allBooksViewController];
  
  return self;
}

@end
