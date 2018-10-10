@class NYPLSettingsPrimaryTableViewController;

typedef NS_ENUM(NSInteger, NYPLSettingsPrimaryTableViewControllerItem) {
  NYPLSettingsPrimaryTableViewControllerItemAccount,
  NYPLSettingsPrimaryTableViewControllerItemAbout,
  NYPLSettingsPrimaryTableViewControllerItemEULA,
  NYPLSettingsPrimaryTableViewControllerItemCustomFeedURL,
  NYPLSettingsPrimaryTableViewControllerItemSoftwareLicenses,
};

NSIndexPath *NYPLSettingsPrimaryTableViewControllerIndexPathFromSettingsItem(
  const NYPLSettingsPrimaryTableViewControllerItem settingsItem);

@protocol NYPLSettingsPrimaryTableViewControllerDelegate

- (void)settingsPrimaryTableViewController:(NYPLSettingsPrimaryTableViewController *)
                                           settingsPrimaryTableViewController
                             didSelectItem:(NYPLSettingsPrimaryTableViewControllerItem)item;

@end

@interface NYPLSettingsPrimaryTableViewController : UITableViewController

@property (nonatomic, weak) id<NYPLSettingsPrimaryTableViewControllerDelegate> delegate;

- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (id)initWithStyle:(UITableViewStyle)style NS_UNAVAILABLE;

@end
