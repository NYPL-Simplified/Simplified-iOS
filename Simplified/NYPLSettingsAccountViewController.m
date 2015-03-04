#import "NYPLAccount.h"
#import "NYPLBookCoverRegistry.h"
#import "NYPLBookRegistry.h"
#import "NYPLConfiguration.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLSettingsCredentialViewController.h"

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

@property (nonatomic) UITextField *barcodeTextField;
@property (nonatomic) BOOL hiddenPIN;
@property (nonatomic) UITextField *PINTextField;

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
  [super viewDidLoad];
  
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
  
  self.barcodeTextField = [[UITextField alloc] initWithFrame:CGRectZero];
  self.barcodeTextField.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                            UIViewAutoresizingFlexibleHeight);
  self.barcodeTextField.font = [UIFont systemFontOfSize:17];
  self.barcodeTextField.placeholder = NSLocalizedString(@"Barcode", nil);
  
  self.PINTextField = [[UITextField alloc] initWithFrame:CGRectZero];
  self.PINTextField.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                        UIViewAutoresizingFlexibleHeight);
  self.PINTextField.font = [UIFont systemFontOfSize:17];
  self.PINTextField.placeholder = NSLocalizedString(@"PIN", nil);
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  self.hiddenPIN = YES;
  self.barcodeTextField.text = [NYPLAccount sharedAccount].barcode;
  self.PINTextField.text = [NYPLAccount sharedAccount].PIN;
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
          message:NSLocalizedString(@"SettingsAccountViewControllerLogoutMessage", nil)
          delegate:self
          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
          otherButtonTitles:NSLocalizedString(@"LogOut", nil), nil]
         show];
      } else {
        __weak NYPLSettingsAccountViewController *const weakSelf = self;
        [[NYPLSettingsCredentialViewController sharedController]
         requestCredentialsUsingExistingBarcode:NO
         message:NYPLSettingsCredentialViewControllerMessageLogIn
         completionHandler:^{
           [weakSelf.tableView reloadData];
         }];
      }
  }
}

#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(__attribute__((unused)) UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *const)indexPath
{
  // This is the amount of horizontal padding Apple uses around the titles in cells by default.
  CGFloat const padding = 16;
  
  BOOL const loggedIn = [[NYPLAccount sharedAccount] hasBarcodeAndPIN];
  
  switch(CellKindFromIndexPath(indexPath)) {
    case CellKindBarcode: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      {
        CGRect frame = cell.contentView.bounds;
        frame.origin.x += padding;
        frame.size.width -= padding * 2;
        self.barcodeTextField.frame = frame;
        [cell.contentView addSubview:self.barcodeTextField];
      }
      return cell;
    }
    case CellKindPIN: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      {
        CGRect frame = cell.contentView.bounds;
        frame.origin.x += padding;
        frame.size.width -= padding * 2;
        self.PINTextField.frame = frame;
        [cell.contentView addSubview:self.PINTextField];
      }
      return cell;
    }
    case CellKindLoginLogout: {
      UITableViewCell *const cell = [[UITableViewCell alloc]
                                     initWithStyle:UITableViewCellStyleValue1
                                     reuseIdentifier:nil];
      cell.textLabel.font = [UIFont systemFontOfSize:17];
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
  if(buttonIndex == alertView.firstOtherButtonIndex) {
    [[NYPLMyBooksDownloadCenter sharedDownloadCenter] reset];
    [[NYPLBookRegistry sharedRegistry] reset];
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
