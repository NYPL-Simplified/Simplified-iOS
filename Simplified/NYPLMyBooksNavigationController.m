#import "NYPLMyBooksViewController.h"

#import "NYPLMyBooksNavigationController.h"

@implementation NYPLMyBooksNavigationController

- (id)init
{
  self = [super initWithRootViewController:[[NYPLMyBooksViewController alloc] init]];
  if(!self) return nil;
  
  return self;
}

@end
