#import "NYPLConfiguration.h"
#import "NYPLSettings.h"

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
      switch (indexPath.row) {
        case 0:
          return NYPLSettingsPrimaryTableViewControllerItemHelpStack;
        default:
          @throw NSInvalidArgumentException;
      }
    case 2:
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
    case 3:
      switch (indexPath.row) {
        case 0:
          return NYPLSettingsPrimaryTableViewControllerItemCustomFeedURL;
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
    case NYPLSettingsPrimaryTableViewControllerItemHelpStack:
      return [NSIndexPath indexPathForRow:0 inSection:1];
    case NYPLSettingsPrimaryTableViewControllerItemAbout:
      return [NSIndexPath indexPathForRow:0 inSection:2];
    case NYPLSettingsPrimaryTableViewControllerItemEULA:
      return [NSIndexPath indexPathForRow:1 inSection:2];
    case NYPLSettingsPrimaryTableViewControllerItemSoftwareLicenses:
      return [NSIndexPath indexPathForRow:2 inSection:2];
    case NYPLSettingsPrimaryTableViewControllerItemCustomFeedURL:
      return [NSIndexPath indexPathForRow:0 inSection:3];
    default:
      @throw NSInvalidArgumentException;
  }
}

@interface NYPLSettingsPrimaryTableViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic) BOOL shouldShowEmptyCustomODPSURLField;

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
  
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];

  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(revealCustomFeedUrl)];
  tap.numberOfTapsRequired = 7;
  
  [[self.navigationController.navigationBar.subviews objectAtIndex:1] setUserInteractionEnabled:YES];
  [[self.navigationController.navigationBar.subviews objectAtIndex:1] addGestureRecognizer:tap];
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
    case NYPLSettingsPrimaryTableViewControllerItemHelpStack: {
      return [self settingsPrimaryTableViewCellWithText:NSLocalizedString(@"Help", nil)];
    }
    case NYPLSettingsPrimaryTableViewControllerItemCustomFeedURL: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      UITextField *field = [[UITextField alloc] initWithFrame:CGRectMake(15, 0, cell.frame.size.width-30, cell.frame.size.height)];
      field.autoresizingMask = UIViewAutoresizingFlexibleWidth;
      field.delegate = self;
      field.text = [NYPLSettings sharedSettings].customMainFeedURL.absoluteString;
      field.placeholder = @"Custom HTTP(S) OPDS URL";
      field.keyboardType = UIKeyboardTypeURL;
      field.returnKeyType = UIReturnKeyDone;
      field.clearButtonMode = UITextFieldViewModeWhileEditing;
      field.spellCheckingType = UITextSpellCheckingTypeNo;
      field.autocorrectionType = UITextAutocorrectionTypeNo;
      field.autocapitalizationType = UITextAutocapitalizationTypeNone;
      [cell.contentView addSubview:field];
      return cell;
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
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  }
  return cell;
}

- (NSInteger)numberOfSectionsInTableView:(__attribute__((unused)) UITableView *)tableView
{
  return 3 + (self.shouldShowEmptyCustomODPSURLField || !![NYPLSettings sharedSettings].customMainFeedURL);
}

-(BOOL)tableView:(__attribute__((unused)) UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (SettingsItemFromIndexPath(indexPath) == NYPLSettingsPrimaryTableViewControllerItemCustomFeedURL) {
    return true;
  }
  return false;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
  
  if (SettingsItemFromIndexPath(indexPath) == NYPLSettingsPrimaryTableViewControllerItemCustomFeedURL && editingStyle == UITableViewCellEditingStyleDelete) {
    
    [NYPLSettings sharedSettings].customMainFeedURL = nil;
    
    [tableView reloadData];
    
    [self exitApp];
    
  }
}

- (NSInteger)tableView:(__attribute__((unused)) UITableView *)tableView
 numberOfRowsInSection:(NSInteger const)section
{
  switch(section) {
    case 2:
      return 3;
    default:
      return 1;
  }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *const)textField
{
  [textField resignFirstResponder];
  
  return YES;
}
-(void)textFieldDidEndEditing:(__attribute__((unused)) UITextField *)textField
{
  NSString *const feed = [textField.text stringByTrimmingCharactersInSet:
                          [NSCharacterSet whitespaceCharacterSet]];
  
  if(feed.length) {
    [NYPLSettings sharedSettings].customMainFeedURL = [NSURL URLWithString:feed];
  } else {
    [NYPLSettings sharedSettings].customMainFeedURL = nil;
  }
  
  [self exitApp];
}

#pragma mark -

- (void)revealCustomFeedUrl
{
  // Insert a URL to force the field to show.
  self.shouldShowEmptyCustomODPSURLField = YES;
  
  [self.tableView reloadData];
}

- (void)exitApp
{
  UIAlertController *alertViewController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"RestartRequired", nil)
                                                                               message:NSLocalizedString(@"RestartRequiredForOPDS", nil)
                                                                        preferredStyle:UIAlertControllerStyleAlert];
  [alertViewController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"NotNow", nil)
                                                          style:UIAlertActionStyleDefault
                                                        handler:nil]];
  [alertViewController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Exit", nil)
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(__attribute__((unused)) UIAlertAction * action) {
                                                          exit(0);
                                                        }]];
  [self presentViewController:alertViewController animated:YES completion:nil];
}

@end
