#import "NYPLSettingsPrimaryTableViewController.h"

@implementation NYPLSettingsPrimaryTableViewController

- (instancetype)init
{
  self = [super initWithStyle:UITableViewStyleGrouped];
  if(!self) return nil;
  
  self.title = NSLocalizedString(@"SettingsPrimaryTableViewControllerTitle", nil);
  
  return self;
}

@end
