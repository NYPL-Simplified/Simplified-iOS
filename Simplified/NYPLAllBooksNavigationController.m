#import "NYPLAllBooksViewController.h"

#import "NYPLAllBooksNavigationController.h"

@implementation NYPLAllBooksNavigationController

- (id)init
{
  self = [super initWithRootViewController:[[NYPLAllBooksViewController alloc] init]];
  if(!self) return nil;
  
  return self;
}

@end
