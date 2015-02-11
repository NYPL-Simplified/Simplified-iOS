#import "NYPLAccount.h"
#import "NYPLMyBooksCoverRegistry.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLMyBooksRegistry.h"
#import "NYPLConfiguration.h"

#import "NYPLSettingsAccountViewController.h"

typedef NS_ENUM(NSInteger, CellKind) {
  CellKindBarcode,
  CellKindPIN,
  CellKindLoginLogout
};

static CellKind CellKindFromIndexPath(NSIndexPath *const indexPath)
{
  switch(indexPath.section) {
    case 0:
      switch(indexPath.row) {
        case 0:
          return CellKindBarcode;
        case 1:
          return CellKindPIN;
        default:
          @throw NSInvalidArgumentException;
      }
    case 1:
      switch(indexPath.row) {
        case 0:
          return CellKindLoginLogout;
        default:
          @throw NSInvalidArgumentException;
      }
    default:
      @throw NSInvalidArgumentException;
  }
}

@interface NYPLSettingsAccountViewController ()

@property (nonatomic) BOOL hiddenPIN;

@end

@implementation NYPLSettingsAccountViewController

#pragma mark NSObject

- (instancetype)init
{
  self = [super initWithStyle:UITableViewStyleGrouped];
  if(!self) return nil;
  
  self.title = NSLocalizedString(@"Library Card", nil);
  
  return self;
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
}

- (void)viewWillAppear:(__attribute__((unused)) BOOL)animated
{
  self.hiddenPIN = YES;
  [self.tableView reloadData];
}

#pragma mark UITableViewDelegate

- (void)tableView:(__attribute__((unused)) UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *const)indexPath
{
  switch(CellKindFromIndexPath(indexPath)) {
    case CellKindBarcode:
      return;
    case CellKindPIN:
      return;
    case CellKindLoginLogout:
      [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
      if([[NYPLAccount sharedAccount] hasBarcodeAndPIN]) {
        [[[UIAlertView alloc]
          initWithTitle:NSLocalizedString(@"LogOut", nil)
          message:NSLocalizedString(@"SettingsViewControllerLogoutMessage", nil)
          delegate:self
          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
          otherButtonTitles:NSLocalizedString(@"LogOut", nil), nil]
         show];
      }
  }
}

#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(__attribute__((unused)) UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *const)indexPath
{
  NSString *const barcode = [NYPLAccount sharedAccount].barcode;
  NSString *const PIN = [NYPLAccount sharedAccount].PIN;
  BOOL const loggedIn = [[NYPLAccount sharedAccount] hasBarcodeAndPIN];
  
  switch(CellKindFromIndexPath(indexPath)) {
    case CellKindBarcode: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleValue1
                                     reuseIdentifier:nil];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      cell.textLabel.text = NSLocalizedString(@"Barcode", nil);
      if(loggedIn) {
        cell.detailTextLabel.textAlignment = NSTextAlignmentLeft;
        cell.detailTextLabel.text = barcode;
      }
      return cell;
    }
    case CellKindPIN: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleValue1
                                     reuseIdentifier:nil];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      cell.textLabel.text = NSLocalizedString(@"PIN", nil);
      if(loggedIn) {
        cell.detailTextLabel.textAlignment = NSTextAlignmentLeft;
        if(self.hiddenPIN) {
          UIButton *const button = [UIButton buttonWithType:UIButtonTypeSystem];
          button.titleLabel.font = [UIFont systemFontOfSize:17];
          [button setTitle:@"Reveal" forState:UIControlStateNormal];
          [button sizeToFit];
          [button addTarget:self
                     action:@selector(didSelectReveal)
           forControlEvents:UIControlEventTouchUpInside];
          cell.accessoryView = button;
        } else {
          cell.detailTextLabel.text = PIN;
        }
      }
      return cell;
    }
    case CellKindLoginLogout: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleValue1
                                     reuseIdentifier:nil];
      cell.textLabel.textColor = [NYPLConfiguration mainColor];
      if(loggedIn) {
        cell.textLabel.text = NSLocalizedString(@"LogOut", nil);
      } else {
        cell.textLabel.text = NSLocalizedString(@"LogIn", nil);
      }
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
    case 0:
      return 2;
    case 1:
      return 1;
    default:
      @throw NSInternalInconsistencyException;
  }
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *const)alertView
didDismissWithButtonIndex:(NSInteger const)buttonIndex
{
  // TODO: This should be done in a centralized manner somewhere else.
  if(buttonIndex == alertView.firstOtherButtonIndex) {
    [[NYPLMyBooksCoverRegistry sharedRegistry] removeAllPinnedThumbnailImages];
    [[NYPLMyBooksDownloadCenter sharedDownloadCenter] reset];
    [[NYPLMyBooksRegistry sharedRegistry] reset];
    [[NYPLAccount sharedAccount] removeBarcodeAndPIN];
  }
  
  [self.tableView reloadData];
}

#pragma mark -

- (void)didSelectReveal
{
  self.hiddenPIN = NO;
  [self.tableView reloadData];
}

@end
