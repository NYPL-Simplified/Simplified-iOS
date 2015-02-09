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
  }
}

static NSString *const reuseIdentifier = @"reuseIdentifier";

@implementation NYPLSettingsPrimaryTableViewController

#pragma mark NSObject

- (instancetype)init
{
  self = [super initWithStyle:UITableViewStyleGrouped];
  if(!self) return nil;
  
  self.title = NSLocalizedString(@"Settings", nil);
  
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:reuseIdentifier];
  
  self.clearsSelectionOnViewWillAppear = NO;
  
  return self;
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
  UITableViewCell *const cell = [self.tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
  if(!cell) {
    // We have a class registered, so this should never be reached.
    @throw NSInternalInconsistencyException;
  }

  switch(SettingsItemFromIndexPath(indexPath)) {
    case NYPLSettingsPrimaryTableViewControllerItemAccount:
      cell.textLabel.text = NSLocalizedString(@"Account", nil);
      break;
    case NYPLSettingsPrimaryTableViewControllerItemCredits:
      cell.textLabel.text =
        NSLocalizedString(@"CreditsAndAcknowledgements", nil);
      break;
    case NYPLSettingsPrimaryTableViewControllerItemFeedback:
      cell.textLabel.text = NSLocalizedString(@"Feedback", nil);
      break;
  }
  
  return cell;
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
      return 2;
    default:
      @throw NSInternalInconsistencyException;
  }
}

@end
