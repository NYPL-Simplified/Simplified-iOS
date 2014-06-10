#import "NYPLMyBooksViewController.h"

#import "NYPLMyBooksNavigationController.h"

@implementation NYPLMyBooksNavigationController

#pragma mark NSObject

- (id)init
{
  self = [super initWithRootViewController:[[NYPLMyBooksViewController alloc] init]];
  if(!self) return nil;
  
  return self;
}

@end
