#import "NYPLConfiguration.h"
#import "NYPLSettingsEULAViewController.h"
#import "NYPLSettingsContentLicenseViewController.h"
#import "NYPLSettingsLicensesTableViewController.h"
#import "NYPLSettingsPrivacyPolicyViewController.h"
#import "SimplyE-Swift.h"

static NYPLSettingsLicensesTableViewControllerItem
SettingsItemFromIndexPath(NSIndexPath *const indexPath)
{
  switch(indexPath.row) {
    case 0:
      return NYPLSettingsLicensesTableViewControllerItemEULA;
    case 1:
      return NYPLSettingsLicensesTableViewControllerItemPrivacyPolicy;
    case 2:
      return NYPLSettingsLicensesTableViewControllerItemContentLicenses;
    case 3:
      return NYPLSettingsLicensesTableViewControllerItemSoftwareLicenses;

    default:
      @throw NSInvalidArgumentException;
  }
}

NSIndexPath *NYPLSettingsLicensesTableViewControllerIndexPathFromSettingsItem(
  const NYPLSettingsLicensesTableViewControllerItem settingsItem)
{
  switch(settingsItem) {
    case NYPLSettingsLicensesTableViewControllerItemEULA:
      return [NSIndexPath indexPathForRow:0 inSection:0];
    case NYPLSettingsLicensesTableViewControllerItemPrivacyPolicy:
      return [NSIndexPath indexPathForRow:1 inSection:0];
    case NYPLSettingsLicensesTableViewControllerItemContentLicenses:
      return [NSIndexPath indexPathForRow:2 inSection:0];
    case NYPLSettingsLicensesTableViewControllerItemSoftwareLicenses:
      return [NSIndexPath indexPathForRow:3 inSection:0];
  }
}

@implementation NYPLSettingsLicensesTableViewController

#pragma mark NSObject

- (instancetype)init
{
  self = [super initWithStyle:UITableViewStyleGrouped];
  if(!self) return nil;
  
  self.title = NSLocalizedString(@"Licenses", nil);
  
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
  NYPLSettingsLicensesTableViewControllerItem item = SettingsItemFromIndexPath(indexPath);
  
  UIViewController *viewController;
  switch(item) {
    case NYPLSettingsLicensesTableViewControllerItemEULA:
      viewController = [[NYPLSettingsEULAViewController alloc] init];
      break;
    case NYPLSettingsLicensesTableViewControllerItemPrivacyPolicy:
      viewController = [[NYPLSettingsPrivacyPolicyViewController alloc] init];
      break;
    case NYPLSettingsLicensesTableViewControllerItemContentLicenses:
      viewController = [[NYPLSettingsContentLicenseViewController alloc] init];
      break;
    case NYPLSettingsLicensesTableViewControllerItemSoftwareLicenses:
      viewController = [[BundledHTMLViewController alloc]
                        initWithFileURL:[[NSBundle mainBundle]
                                         URLForResource:@"software-licenses"
                                         withExtension:@"html"]
                        title:NSLocalizedString(@"SoftwareLicenses", nil)];
      break;
  }
  
  [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(__attribute__((unused)) UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *const)indexPath
{
  switch(SettingsItemFromIndexPath(indexPath)) {
    case NYPLSettingsLicensesTableViewControllerItemEULA: {
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
    case NYPLSettingsLicensesTableViewControllerItemPrivacyPolicy: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      cell.textLabel.text = NSLocalizedString(@"PrivacyPolicy", nil);
      cell.textLabel.font = [UIFont systemFontOfSize:17];
      if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      }
      return cell;
    }
    case NYPLSettingsLicensesTableViewControllerItemContentLicenses: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      cell.textLabel.text = NSLocalizedString(@"ContentLicenses", nil);
      cell.textLabel.font = [UIFont systemFontOfSize:17];
      if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      }
      return cell;
    }
    case NYPLSettingsLicensesTableViewControllerItemSoftwareLicenses: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      cell.textLabel.text = NSLocalizedString(@"SoftwareLicenses", nil);
      cell.textLabel.font = [UIFont systemFontOfSize:17];
      if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      }
      return cell;
    }
  }
}

- (NSInteger)tableView:(__attribute__((unused)) UITableView *)tableView
 numberOfRowsInSection:(__attribute__((unused)) NSInteger)section
{
  return 4;
}


@end
