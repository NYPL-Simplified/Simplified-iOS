#import "NYPLConfiguration.h"

#import "NYPLSettingsPrimaryTableViewController.h"

static NYPLSettingsPrimaryTableViewControllerItem
SettingsItemFromIndexPath(NSIndexPath *const indexPath)
{
  switch(indexPath.section) {
    case 0:
      switch(indexPath.row) {
        case 0:
          return NYPLSettingsPrimaryTableViewControllerItemAccount;
        default:
          @throw NSInvalidArgumentException;
      }
    case 1:
      switch(indexPath.row) {
        case 0:
          return NYPLSettingsPrimaryTableViewControllerItemFeedback;
        case 1:
          return NYPLSettingsPrimaryTableViewControllerItemCredits;
        case 2:
          return NYPLSettingsPrimaryTableViewControllerItemEULA;
        default:
          @throw NSInvalidArgumentException;
      }
    default:
      @throw NSInvalidArgumentException;
  }
}

NSIndexPath *NYPLSettingsPrimaryTableViewControllerIndexPathFromSettingsItem(
  const NYPLSettingsPrimaryTableViewControllerItem settingsItem)
{
  switch(settingsItem) {
    case NYPLSettingsPrimaryTableViewControllerItemAccount:
      return [NSIndexPath indexPathForRow:0 inSection:0];
    case NYPLSettingsPrimaryTableViewControllerItemFeedback:
      return [NSIndexPath indexPathForRow:0 inSection:1];
    case NYPLSettingsPrimaryTableViewControllerItemCredits:
      return [NSIndexPath indexPathForRow:1 inSection:1];
    case NYPLSettingsPrimaryTableViewControllerItemEULA:
      return [NSIndexPath indexPathForRow:2 inSection:1];
  }
}

@implementation NYPLSettingsPrimaryTableViewController

#pragma mark NSObject

- (instancetype)init
{
  self = [super initWithStyle:UITableViewStyleGrouped];
  if(!self) return nil;
  
  self.title = NSLocalizedString(@"Settings", nil);
  
  self.clearsSelectionOnViewWillAppear = NO;
  
  return self;
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
}

#pragma mark UITableViewDelegate

- (void)tableView:(__attribute__((unused)) UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *const)indexPath
{
  [self.delegate settingsPrimaryTableViewController:self
                                      didSelectItem:SettingsItemFromIndexPath(indexPath)];
}

#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(__attribute__((unused)) UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *const)indexPath
{
  switch(SettingsItemFromIndexPath(indexPath)) {
    case NYPLSettingsPrimaryTableViewControllerItemAccount: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      cell.textLabel.text = NSLocalizedString(@"Library Card", nil);
      cell.textLabel.font = [UIFont systemFontOfSize:17];
      if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      }
      return cell;
    }
    case NYPLSettingsPrimaryTableViewControllerItemCredits: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      cell.textLabel.text = NSLocalizedString(@"Acknowledgements", nil);
      cell.textLabel.font = [UIFont systemFontOfSize:17];
      if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      }
      return cell;
    }
    case NYPLSettingsPrimaryTableViewControllerItemFeedback: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      cell.textLabel.text = NSLocalizedString(@"Feedback", nil);
      cell.textLabel.font = [UIFont systemFontOfSize:17];
      if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      }
      return cell;
    }
    case NYPLSettingsPrimaryTableViewControllerItemEULA: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      cell.textLabel.text = NSLocalizedString(@"EULA", nil);
      cell.textLabel.font = [UIFont systemFontOfSize:17];
      if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      }
      return cell;
    }
  }
}

- (NSInteger)numberOfSectionsInTableView:(__attribute__((unused)) UITableView *)tableView
{
  return 2;
}

- (NSInteger)tableView:(__attribute__((unused)) UITableView *)tableView
 numberOfRowsInSection:(NSInteger const)section
{
  switch(section) {
    case 0:
      return 1;
    case 1:
      return 3;
    default:
      @throw NSInternalInconsistencyException;
  }
}

@end
