#import "NYPLCatalogViewController.h"

#import "NYPLCatalogNavigationController.h"

@implementation NYPLCatalogNavigationController

#pragma mark NSObject

- (id)init
{
  self = [super initWithRootViewController:[[NYPLCatalogViewController alloc] init]];
  if(!self) return nil;
  
  return self;
}

@end
