#import "NYPLHoldsViewController.h"

#import "NYPLHoldsNavigationController.h"

@implementation NYPLHoldsNavigationController

#pragma mark NSObject

- (instancetype)init
{
  self = [super initWithRootViewController:[[NYPLHoldsViewController alloc] init]];
  if(!self) return nil;
  
  self.tabBarItem.image = [UIImage imageNamed:@"Holds"];
  
  return self;
}

@end
