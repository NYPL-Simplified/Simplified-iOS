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
  CellKindEULA,
  CellKindSyncButton,
  CellKindAbout,
  CellKindPrivacyPolicy,
  CellKindContentLicense,
  CellKindContact
};

typedef NS_ENUM(NSInteger, Section) {
  SectionEULA = 0,
  SectionSync = 1,
  SectionLicenses = 2,
};

static CellKind CellKindFromIndexPath(NSIndexPath *const indexPath)
{
  switch(indexPath.section) {
      
    case 0:
      switch(indexPath.row) {
        case 0:
          return CellKindEULA;
        default:
          @throw NSInvalidArgumentException;
      }
      
    case 1:
        switch (indexPath.row) {
          case 0:
            return CellKindSyncButton;
          default:
            @throw NSInvalidArgumentException;
        }
      
    case 2:
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
@property (nonatomic) UITableViewCell *eulaCell;

@end


@implementation NYPLSettingsClassicsAccountDetailViewController

- (instancetype)init
{
  self = [super initWithStyle:UITableViewStyleGrouped];
  if(!self) return nil;
  
  self.title = NSLocalizedString(@"Account", nil);
  
//  [[NSNotificationCenter defaultCenter]
//   addObserver:self
//   selector:@selector(accountDidChange)
//   name:NYPLAccountDidChangeNotification
//   object:nil];

  return self;
}

//- (void)dealloc
//{
//  [[NSNotificationCenter defaultCenter] removeObserver:self];
//}

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
  switch(CellKindFromIndexPath(indexPath)) {
    case CellKindEULA: {
      UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
      Account *accountItem = [[AccountsManager sharedInstance] account:2];    //GODO hardcoded instant classic
      if (accountItem.eulaIsAccepted == YES) {
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CheckboxOff"]];
        accountItem.eulaIsAccepted = NO;
      } else {
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CheckboxOn"]];
        accountItem.eulaIsAccepted = YES;
      }
      break;
    }
    case CellKindSyncButton: {
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
  // This is the amount of horizontal padding Apple uses around the titles in cells by default.
  CGFloat const padding = 16;
  
  switch(CellKindFromIndexPath(indexPath)) {
    case CellKindEULA: {
      self.eulaCell = [[UITableViewCell alloc]
                       initWithStyle:UITableViewCellStyleDefault
                       reuseIdentifier:nil];
      Account *accountItem = [[AccountsManager sharedInstance] account:2];
      if (accountItem.eulaIsAccepted) {
        self.eulaCell.accessoryView = [[UIImageView alloc] initWithImage:
                                       [UIImage imageNamed:@"CheckboxOn"]];
      } else {
        self.eulaCell.accessoryView = [[UIImageView alloc] initWithImage:
                                       [UIImage imageNamed:@"CheckboxOff"]];
      }
      self.eulaCell.selectionStyle = UITableViewCellSelectionStyleNone;
      self.eulaCell.textLabel.font = [UIFont systemFontOfSize:13];
      self.eulaCell.textLabel.text = NSLocalizedString(@"SettingsAccountEULACheckbox",
                                                       @"Statement letting a user know that they must agree to the User Agreement terms.");
      self.eulaCell.textLabel.numberOfLines = 2;
      return self.eulaCell;
    }
    case CellKindSyncButton: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      UISwitch* switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
      Account *account = [[AccountsManager sharedInstance] account:2];
      if (account.syncIsEnabled) {
        [switchView setOn:YES];
      } else {
        [switchView setOn:NO];
      }
      cell.accessoryView = switchView;
      [switchView addTarget:self action:@selector(syncSwitchChanged:) forControlEvents:UIControlEventValueChanged];
      [cell.contentView addSubview:switchView];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      cell.textLabel.font = [UIFont systemFontOfSize:17];
      cell.textLabel.text = NSLocalizedString(@"SettingsAccountSyncTitle",
                                              @"Title for switch to turn on or off syncing of the place where a user was reading a book.");
      return cell;
    }
    case CellKindAbout: {
      Account *accountItem = [[AccountsManager sharedInstance] account:2];
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
  return 3;
}

- (NSInteger)tableView:(__attribute__((unused)) UITableView *)tableView
 numberOfRowsInSection:(NSInteger const)section
{
  switch(section) {
    case SectionEULA:
      return 1;
    case SectionSync:
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
    [subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:titleLabel withOffset:4];
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


//- (void)accountDidChange
//{
//
//}

@end
