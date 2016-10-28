#import "NYPLSettingsPrimaryTableViewController.h"

typedef NS_ENUM(NSInteger, NYPLSettingsLicensesTableViewControllerItem) {
  NYPLSettingsLicensesTableViewControllerItemEULA,
  NYPLSettingsLicensesTableViewControllerItemPrivacyPolicy,
  NYPLSettingsLicensesTableViewControllerItemContentLicenses,
  NYPLSettingsLicensesTableViewControllerItemSoftwareLicenses
};

NSIndexPath *NYPLSettingsLicensesTableViewControllerIndexPathFromSettingsItem(
  const NYPLSettingsLicensesTableViewControllerItem settingsItem);

@interface NYPLSettingsLicensesTableViewController : UITableViewController

- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (id)initWithStyle:(UITableViewStyle)style NS_UNAVAILABLE;

@end
