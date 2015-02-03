@protocol NYPLSettingsPrimaryTableViewControllerDelegate

@end

@interface NYPLSettingsPrimaryTableViewController : UITableViewController

@property (nonatomic, weak) id<NYPLSettingsPrimaryTableViewControllerDelegate> delegate;

- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (id)initWithStyle:(UITableViewStyle)style NS_UNAVAILABLE;

@end
