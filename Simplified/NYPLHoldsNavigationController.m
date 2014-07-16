#import "NYPLHoldsViewController.h"

#import "NYPLHoldsNavigationController.h"

@implementation NYPLHoldsNavigationController

#pragma mark NSObject

- (instancetype)init
{
  self = [super initWithRootViewController:[[NYPLHoldsViewController alloc] init]];
  if(!self) return nil;
  
  return self;
}

@end
