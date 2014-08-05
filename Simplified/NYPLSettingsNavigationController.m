#import "NYPLSettingsViewController.h"

#import "NYPLSettingsNavigationController.h"

@implementation NYPLSettingsNavigationController

#pragma mark NSObject

- (instancetype)init
{
  self = [super initWithRootViewController:[[NYPLSettingsViewController alloc] init]];
  if(!self) return nil;
  
  self.tabBarItem.image = [UIImage imageNamed:@"Settings"];
  
  return self;
}

@end
