@import LocalAuthentication;

#import "NYPLAccount.h"
#import "NYPLAlertController.h"
#import "NYPLConfiguration.h"
#import "NYPLRootTabBarController.h"
#import "NYPLSettings.h"
#import "NYPLSettingsEULAViewController.h"
#import "SimplyE-Swift.h"
#import "UIView+NYPLViewAdditions.h"
#import <PureLayout/PureLayout.h>

#import "NYPLSettingsClassicsAccountDetailViewController.h"

typedef NS_ENUM(NSInteger, CellKind) {
  CellKindAgeCheck,
  CellKindAbout,
  CellKindPrivacyPolicy,
  CellKindContentLicense,
  CellKindContact
};

typedef NS_ENUM(NSInteger, Section) {
  SectionAgreements = 0,
  SectionLicenses = 1,
};

static CellKind CellKindFromIndexPath(NSIndexPath *const indexPath)
{
  switch(indexPath.section) {
      
    case 0:
      switch(indexPath.row) {
        case 0:
          return CellKindAgeCheck;
        default:
          @throw NSInvalidArgumentException;
      }
      
    case 1:
        switch (indexPath.row) {
          case 0:
            return CellKindAbout;
          case 1:
            return CellKindPrivacyPolicy;
          case 2:
            return CellKindContentLicense;
          case 3:
            return CellKindContact;
          default:
            @throw NSInvalidArgumentException;
        }
      
    default:
      @throw NSInvalidArgumentException;
  }
}

@interface NYPLSettingsClassicsAccountDetailViewController ()

@property (nonatomic, copy) void (^completionHandler)();
@property (nonatomic) UITableViewCell *ageCheckCell;

@end


@implementation NYPLSettingsClassicsAccountDetailViewController

- (instancetype)init
{
  self = [super initWithStyle:UITableViewStyleGrouped];
  if(!self) return nil;

  return self;
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
  
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"EULA"
                                                                            style:UIBarButtonItemStylePlain
                                                                           target:self
                                                                           action:@selector(showEULA)];
}

#pragma mark UITableViewDelegate

- (void)tableView:(__attribute__((unused)) UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *const)indexPath
{
  Account *accountItem = [[AccountsManager sharedInstance] account:2];      //GODO hardcoded instant classic
  switch(CellKindFromIndexPath(indexPath)) {
    case CellKindAgeCheck: {
      UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
      if (accountItem.userAboveAgeLimit == YES) {
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CheckboxOff"]];
        accountItem.userAboveAgeLimit = NO;
      } else {
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CheckboxOn"]];
        accountItem.userAboveAgeLimit = YES;
      }
      break;
    }
    case CellKindAbout: {
      RemoteHTMLViewController *vc = [[RemoteHTMLViewController alloc]
                                      initWithURL:[[NYPLSettings sharedSettings] acknowledgmentsURL]
                                      title:NSLocalizedString(@"About", nil)
                                      failureMessage:NSLocalizedString(@"SettingsConnectionFailureMessage", nil)];
      [self.navigationController pushViewController:vc animated:true];
      break;
    }
    case CellKindPrivacyPolicy: {
      RemoteHTMLViewController *vc = [[RemoteHTMLViewController alloc]
                                      initWithURL:[[NYPLSettings sharedSettings] privacyPolicyURL]
                                      title:NSLocalizedString(@"PrivacyPolicy", nil)
                                      failureMessage:NSLocalizedString(@"SettingsConnectionFailureMessage", nil)];
      [self.navigationController pushViewController:vc animated:true];
      break;
    }
    case CellKindContentLicense: {
      RemoteHTMLViewController *vc = [[RemoteHTMLViewController alloc]
                                      initWithURL:[[NYPLSettings sharedSettings] contentLicenseURL]
                                      title:NSLocalizedString(@"ContentLicenses", nil)
                                      failureMessage:NSLocalizedString(@"SettingsConnectionFailureMessage", nil)];
      [self.navigationController pushViewController:vc animated:true];
      break;
    }
    case CellKindContact: {
      //GODO temp until further information
      break;
    }
  }
}

- (void)showDetailVC:(UIViewController *)vc fromIndexPath:(NSIndexPath *)indexPath
{
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    [self.splitViewController showDetailViewController:[[UINavigationController alloc]
                                                        initWithRootViewController:vc]
                                                sender:self];
  } else {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.splitViewController showDetailViewController:vc sender:self];
  }
}

#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(__attribute__((unused)) UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *const)indexPath
{
  Account *accountItem = [[AccountsManager sharedInstance] account:2];
  switch(CellKindFromIndexPath(indexPath)) {
    case CellKindAgeCheck: {
      self.ageCheckCell = [[UITableViewCell alloc]
                           initWithStyle:UITableViewCellStyleDefault
                           reuseIdentifier:nil];
      if (accountItem.userAboveAgeLimit) {
        self.ageCheckCell.accessoryView = [[UIImageView alloc] initWithImage:
                                           [UIImage imageNamed:@"CheckboxOn"]];
      } else {
        self.ageCheckCell.accessoryView = [[UIImageView alloc] initWithImage:
                                           [UIImage imageNamed:@"CheckboxOff"]];
      }
      self.ageCheckCell.selectionStyle = UITableViewCellSelectionStyleNone;
      self.ageCheckCell.textLabel.font = [UIFont systemFontOfSize:13];
      self.ageCheckCell.textLabel.text = NSLocalizedString(@"SettingsAccountAgeCheckbox",
                                                           @"Statement that confirms if a user meets the age requirement to download books");
      self.ageCheckCell.textLabel.numberOfLines = 2;
      return self.ageCheckCell;
    }
    case CellKindAbout: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      cell.textLabel.font = [UIFont systemFontOfSize:17];
      cell.textLabel.text = [NSString stringWithFormat:@"About %@",accountItem.name];
      return cell;
    }
    case CellKindPrivacyPolicy: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      cell.textLabel.font = [UIFont systemFontOfSize:17];
      cell.textLabel.text = NSLocalizedString(@"PrivacyPolicy", nil);
      return cell;
    }
    case CellKindContentLicense: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      cell.textLabel.font = [UIFont systemFontOfSize:17];
      cell.textLabel.text = NSLocalizedString(@"ContentLicenses", nil);
      return cell;
    }
    case CellKindContact: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      cell.textLabel.font = [UIFont systemFontOfSize:17];
      cell.textLabel.text = NSLocalizedString(@"Contact",
                                              @"Setting to let a user contact or communicate with a particular Library");
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
    case SectionAgreements:
      return 1;
    case SectionLicenses:
      return 4;
    default:
      @throw NSInternalInconsistencyException;
  }
}

- (CGFloat)tableView:(__unused UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
  if (section == 0) {
    return UITableViewAutomaticDimension;
  } else {
    return 0;
  }
}

-(CGFloat)tableView:(__unused UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section
{
  if (section == 0) {
    return 80;
  } else {
    return 0;
  }
}

- (CGFloat)tableView:(__unused UITableView *)tableView estimatedHeightForRowAtIndexPath:(__unused NSIndexPath *)indexPath
{
  return 44;
}

- (UIView *)tableView:(__unused UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
  if (section == 0) {
    Account *account = [[AccountsManager sharedInstance] account:2];
    
    UIView *containerView = [[UIView alloc] init];
    UILabel *titleLabel = [[UILabel alloc] init];
    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.numberOfLines = 0;
    UIImageView *logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:account.logo]];
    logoView.contentMode = UIViewContentModeScaleAspectFit;
    
    titleLabel.text = account.name;
    titleLabel.font = [UIFont systemFontOfSize:14];
    subtitleLabel.text = account.subtitle;
    subtitleLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:12];
    
    [containerView addSubview:titleLabel];
    [containerView addSubview:subtitleLabel];
    [containerView addSubview:logoView];
    
    [logoView autoSetDimensionsToSize:CGSizeMake(45, 45)];
    [logoView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:16];
    [logoView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:16];
    
    [titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:16];
    [titleLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:16];
    [titleLabel autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:logoView withOffset:8];
    
    [subtitleLabel autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:titleLabel];
    [subtitleLabel autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:titleLabel];
    [subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:titleLabel withOffset:0];
    [subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:20];
    
    return containerView;
  } else {
    return nil;
  }
}

#pragma mark -

- (void)showEULA
{
  UIViewController *eulaViewController = [[NYPLSettingsEULAViewController alloc] init];
  UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:eulaViewController];
  [self.navigationController presentViewController:navVC animated:YES completion:nil];
}

- (void)syncSwitchChanged:(id)sender
{
  Account *account = [[AccountsManager sharedInstance] account:[[NYPLSettings sharedSettings] currentAccountIdentifier]];
  UISwitch *switchControl = sender;
  if (switchControl.on) {
    account.syncIsEnabled = YES;
  } else {
    account.syncIsEnabled = NO;
  }
}

@end
