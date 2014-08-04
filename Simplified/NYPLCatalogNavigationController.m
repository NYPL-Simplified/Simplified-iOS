#import "NYPLCatalogRootViewController.h"

#import "NYPLCatalogNavigationController.h"

@implementation NYPLCatalogNavigationController

#pragma mark NSObject

- (instancetype)init
{
  self = [super initWithRootViewController:[[NYPLCatalogRootViewController alloc] init]];
  if(!self) return nil;
  
  self.tabBarItem.image = [UIImage imageNamed:@"Catalog"];
  
  return self;
}

@end
