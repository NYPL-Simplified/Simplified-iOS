#import "NYPLSettingsPrimaryTableViewController.h"

#import "NYPLSettingsPrimaryNavigationController.h"

@interface NYPLSettingsPrimaryNavigationController ()

@property (nonatomic) NYPLSettingsPrimaryTableViewController *tableViewController;

@end

@implementation NYPLSettingsPrimaryNavigationController

#pragma mark NSObject

- (instancetype)init
{
  NYPLSettingsPrimaryTableViewController *const tableViewController =
    [[NYPLSettingsPrimaryTableViewController alloc] init];
  
  self = [super initWithRootViewController:tableViewController];
  if(!self) return nil;
  
  self.tableViewController = tableViewController;
  
  return self;
}

#pragma mark -

- (NYPLSettingsPrimaryTableViewController *)primaryTableViewController
{
  return self.tableViewController;
}

@end
