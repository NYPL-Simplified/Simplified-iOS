#import "NYPLAllBooksViewController.h"

#import "NYPLAllBooksNavigationController.h"

@implementation NYPLAllBooksNavigationController

#pragma mark NSObject

- (id)init
{
  self = [super initWithRootViewController:[[NYPLAllBooksViewController alloc] init]];
  if(!self) return nil;
  
  return self;
}

@end
