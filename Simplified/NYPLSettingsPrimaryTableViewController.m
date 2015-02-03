#import "NYPLSettingsPrimaryTableViewController.h"

static NYPLSettingsPrimaryTableViewControllerItem
SettingsItemFromIndexPath(NSIndexPath *const indexPath)
{
  switch(indexPath.section) {
    case 0:
      switch(indexPath.row) {
        case 0:
          return NYPLSettingsPrimaryTableViewControllerItemFeedback;
        case 1:
          return NYPLSettingsPrimaryTableViewControllerItemCreditsAndAcknowledgements;
        default:
          @throw NSInvalidArgumentException;
      }
    default:
      @throw NSInvalidArgumentException;
  }
}

__attribute__((unused))
static NSIndexPath *IndexPathFromSettingsItem(
  const NYPLSettingsPrimaryTableViewControllerItem settingsItem)
{
  switch(settingsItem) {
    case NYPLSettingsPrimaryTableViewControllerItemFeedback:
      return [NSIndexPath indexPathForRow:0 inSection:0];
    case NYPLSettingsPrimaryTableViewControllerItemCreditsAndAcknowledgements:
      return [NSIndexPath indexPathForRow:1 inSection:0];
  }
}

static NSString *const reuseIdentifier = @"reuseIdentifier";

@implementation NYPLSettingsPrimaryTableViewController

#pragma mark NSObject

- (instancetype)init
{
  self = [super initWithStyle:UITableViewStyleGrouped];
  if(!self) return nil;
  
  self.title = NSLocalizedString(@"SettingsPrimaryTableViewControllerTitle", nil);
  
  assert(self.tableView);
  
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:reuseIdentifier];
  
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
    case NYPLSettingsPrimaryTableViewControllerItemCreditsAndAcknowledgements:
      cell.textLabel.text =
        NSLocalizedString(@"SettingsPrimaryTableViewControllerCreditsAndAcknowledgements", nil);
      break;
    case NYPLSettingsPrimaryTableViewControllerItemFeedback:
      cell.textLabel.text = NSLocalizedString(@"SettingsPrimaryTableViewControllerFeedback", nil);
      break;
  }
  
  return cell;
}

- (NSInteger)numberOfSectionsInTableView:(__attribute__((unused)) UITableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(__attribute__((unused)) UITableView *)tableView
 numberOfRowsInSection:(NSInteger const)section
{
  switch(section) {
    case 0:
      return 2;
    default:
      @throw NSInternalInconsistencyException;
  }
}

@end
