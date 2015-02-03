#import "NYPLSettingsPrimaryNavigationController.h"

@implementation NYPLSettingsPrimaryNavigationController

#pragma mark NSObject

- (instancetype)init
{
  self = [super initWithRootViewController:[[UIViewController alloc] init]];
  if(!self) return nil;
  
  ((UIViewController *)self.viewControllers[0]).view.backgroundColor = [UIColor redColor];
  
  return self;
}

@end
