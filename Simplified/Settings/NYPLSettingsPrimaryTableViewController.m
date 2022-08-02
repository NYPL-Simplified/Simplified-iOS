#import "SimplyE-Swift.h"

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
          return NYPLSettingsPrimaryTableViewControllerItemAbout;
        case 1:
          return NYPLSettingsPrimaryTableViewControllerItemEULA;
        case 2:
          return NYPLSettingsPrimaryTableViewControllerItemSoftwareLicenses;
        default:
          @throw NSInvalidArgumentException;
      }
    case 2:
      switch (indexPath.row) {
        case 0:
          return NYPLSettingsPrimaryTableViewControllerItemDeveloperSettings;
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
    case NYPLSettingsPrimaryTableViewControllerItemAbout:
      return [NSIndexPath indexPathForRow:0 inSection:1];
    case NYPLSettingsPrimaryTableViewControllerItemEULA:
      return [NSIndexPath indexPathForRow:1 inSection:1];
    case NYPLSettingsPrimaryTableViewControllerItemSoftwareLicenses:
      return [NSIndexPath indexPathForRow:2 inSection:1];
    case NYPLSettingsPrimaryTableViewControllerItemDeveloperSettings:
      return [NSIndexPath indexPathForRow:0 inSection:2];
    default:
      @throw NSInvalidArgumentException;
  }
}

@interface NYPLSettingsPrimaryTableViewController ()

@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic) BOOL shouldShowDeveloperMenuItem;

@end

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
  self.view.backgroundColor = [NYPLConfiguration primaryBackgroundColor];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  if (self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath) {
      [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
    }
  }
}

#pragma mark UITableViewDelegate

- (void)tableView:(__attribute__((unused)) UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *const)indexPath
{
  NYPLSettingsPrimaryTableViewControllerItem item = SettingsItemFromIndexPath(indexPath);
  [self.delegate settingsPrimaryTableViewController:self didSelectItem:item];
}

- (CGFloat)tableView:(__unused UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
  NSInteger sectionCount = [self numberOfSectionsInTableView:self.tableView];
  if (section == (sectionCount-1))
    return 45.0;
  return 0;
}

- (UIView *)tableView:(__unused UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
  NSInteger sectionCount = [self numberOfSectionsInTableView:self.tableView];
  if (section == (sectionCount-1)) {
    if (self.infoLabel == nil) {
      self.infoLabel = [[UILabel alloc] init];
      [self.infoLabel setFont:[UIFont systemFontOfSize:12]];
      NSString *productName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
      NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
      NSString *build = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
      self.infoLabel.text = [NSString stringWithFormat:@"%@ version %@ (%@)", productName, version, build];
      self.infoLabel.textAlignment = NSTextAlignmentCenter;
      [self.infoLabel sizeToFit];

      UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(revealDeveloperSettings)];
      tap.numberOfTapsRequired = 7;
      [self.infoLabel setUserInteractionEnabled:YES];
      [self.infoLabel addGestureRecognizer:tap];
    }
    return self.infoLabel;
  }
  return nil;
}

#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(__attribute__((unused)) UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *const)indexPath
{
  switch(SettingsItemFromIndexPath(indexPath)) {
    case NYPLSettingsPrimaryTableViewControllerItemSoftwareLicenses: {
      return [self settingsPrimaryTableViewCellWithText:NSLocalizedString(@"SoftwareLicenses", nil)];
    }
    case NYPLSettingsPrimaryTableViewControllerItemEULA: {
      return [self settingsPrimaryTableViewCellWithText:NSLocalizedString(@"EULA", nil)];
    }
    case NYPLSettingsPrimaryTableViewControllerItemAccount: {
      return [self settingsPrimaryTableViewCellWithText:NSLocalizedString(@"Accounts", nil)];
    }
    case NYPLSettingsPrimaryTableViewControllerItemAbout: {
      return [self settingsPrimaryTableViewCellWithText:NSLocalizedString(@"AboutApp", nil)];
    }
    case NYPLSettingsPrimaryTableViewControllerItemDeveloperSettings: {
      return [self settingsPrimaryTableViewCellWithText:NSLocalizedString(@"Testing", nil)];
    }
    default:
      return nil;
  }
}

- (UITableViewCell *)settingsPrimaryTableViewCellWithText:(NSString *)text
{
  UITableViewCell *const cell = [[UITableViewCell alloc]
                                 initWithStyle:UITableViewCellStyleDefault
                                 reuseIdentifier:nil];
  cell.textLabel.text = text;
  cell.textLabel.font = [UIFont systemFontOfSize:17];
  if (self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  } else {
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
  return cell;
}

- (NSInteger)numberOfSectionsInTableView:(__attribute__((unused)) UITableView *)tableView
{
  return 2 + (self.shouldShowDeveloperMenuItem || !![NYPLSettings sharedSettings].customMainFeedURL);
}

-(BOOL)tableView:(__attribute__((unused)) UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
  return SettingsItemFromIndexPath(indexPath) == NYPLSettingsPrimaryTableViewControllerItemDeveloperSettings;
}

- (NSInteger)tableView:(__attribute__((unused)) UITableView *)tableView
 numberOfRowsInSection:(NSInteger const)section
{
  switch(section) {
    case 1:
      return 3;
    default:
      return 1;
  }
}

#pragma mark -

- (void)revealDeveloperSettings
{
  // Insert a URL to force the field to show.
  self.shouldShowDeveloperMenuItem = YES;
  
  [self.tableView reloadData];
}

@end
