#import "NYPLSettingsPrimaryTableViewController.h"

#import "NYPLSettingsPrimaryNavigationController.h"

@interface NYPLSettingsPrimaryNavigationController ()
  <NYPLSettingsPrimaryTableViewControllerDelegate>

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

#pragma mark NYPLSettingsPrimaryTableViewControllerDelegate

- (void)settingsPrimaryTableViewController:(__attribute__((unused))
                                            NYPLSettingsPrimaryTableViewController *)
                                           settingsPrimaryTableViewController
                             didSelectItem:(NYPLSettingsPrimaryTableViewControllerItem const)item
{
  switch(item) {
    case NYPLSettingsPrimaryTableViewControllerItemCreditsAndAcknowledgements:
      // TODO
      break;
    case NYPLSettingsPrimaryTableViewControllerItemFeedback:
      // TODO
      break;
  }
}

@end
