#import "HSHelpStack.h"
#import "HSDeskGear.h"
#import "NYPLSettingsPrimaryNavigationController.h"
#import "NYPLSettingsPrimaryTableViewController.h"
#import "NYPLSettingsEULAViewController.h"
#import "NYPLSettings.h"
#import "NYPLBook.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "SimplyE-Swift.h"

#import "NYPLSettingsSplitViewController.h"

@interface NYPLSettingsSplitViewController ()
  <UISplitViewControllerDelegate, NYPLSettingsPrimaryTableViewControllerDelegate>

@property (nonatomic) NYPLSettingsPrimaryNavigationController *primaryNavigationController;

@end

@implementation NYPLSettingsSplitViewController

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.delegate = self;
  
  self.title = NSLocalizedString(@"Settings", nil);
  self.tabBarItem.image = [UIImage imageNamed:@"Settings"];
  
  self.primaryNavigationController = [[NYPLSettingsPrimaryNavigationController alloc] init];
  self.primaryNavigationController.primaryTableViewController.delegate = self;
  
  NSArray *accounts = [[NYPLSettings sharedSettings] settingsAccountsList];
  
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    self.viewControllers = @[self.primaryNavigationController,
                             [[UINavigationController alloc] initWithRootViewController:
                              [[NYPLSettingsAccountsTableViewController alloc] initWithAccounts:accounts]]];
    [self.primaryNavigationController.primaryTableViewController.tableView
     selectRowAtIndexPath:NYPLSettingsPrimaryTableViewControllerIndexPathFromSettingsItem(
                            NYPLSettingsPrimaryTableViewControllerItemAccount)
     animated:NO
     scrollPosition:UITableViewScrollPositionMiddle];
  } else {
    self.viewControllers = @[self.primaryNavigationController];
  }
  
  self.presentsWithGesture = NO;
  self.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
  
  return self;
}

#pragma mark UISplitViewControllerDelegate

- (BOOL)splitViewController:(__attribute__((unused)) UISplitViewController *)splitViewController
collapseSecondaryViewController:(__attribute__((unused)) UIViewController *)secondaryViewController
ontoPrimaryViewController:(__attribute__((unused)) UIViewController *)primaryViewController
{
  return YES;
}

#pragma mark NYPLSettingsPrimaryTableViewControllerDelegate

- (void)settingsPrimaryTableViewController:(NYPLSettingsPrimaryTableViewController *const)
                                           settingsPrimaryTableViewController
                             didSelectItem:(NYPLSettingsPrimaryTableViewControllerItem const)item
{
  UIViewController *viewController;
  NSArray *accounts;
  switch(item) {
    case NYPLSettingsPrimaryTableViewControllerItemAccount:
      accounts = [[NYPLSettings sharedSettings] settingsAccountsList];
      viewController = [[NYPLSettingsAccountsTableViewController alloc] initWithAccounts:accounts];
      break;
    case NYPLSettingsPrimaryTableViewControllerItemAbout:
      viewController = [[RemoteHTMLViewController alloc]
                        initWithURL:[NSURL URLWithString:NYPLAcknowledgementsURLString]
                        title:NSLocalizedString(@"AboutApp", nil)
                        failureMessage:NSLocalizedString(@"SettingsConnectionFailureMessage", nil)];
      break;
    case NYPLSettingsPrimaryTableViewControllerItemEULA:
      viewController = [[RemoteHTMLViewController alloc]
                        initWithURL:[NSURL URLWithString:NYPLUserAgreementURLString]
                        title:NSLocalizedString(@"EULA", nil)
                        failureMessage:NSLocalizedString(@"SettingsConnectionFailureMessage", nil)];
      break;
    case NYPLSettingsPrimaryTableViewControllerItemSoftwareLicenses:
      viewController = [[BundledHTMLViewController alloc]
                        initWithFileURL:[[NSBundle mainBundle]
                                         URLForResource:@"software-licenses"
                                         withExtension:@"html"]
                        title:NSLocalizedString(@"SoftwareLicenses", nil)];
      break;
    case NYPLSettingsPrimaryTableViewControllerItemHelpStack: {
      [[HSHelpStack instance] setThemeFrompList:@"HelpStackTheme"];
      HSDeskGear *deskGear = [[HSDeskGear alloc]
                              initWithInstanceBaseUrl:@"######## REPLACE #########"
                              token:@"######## REPLACE #########"
                              andBrand:@"######## REPLACE #########"];
      
      HSHelpStack *helpStack = [HSHelpStack instance];
      helpStack.gear = deskGear;

      if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIStoryboard* helpStoryboard = [UIStoryboard storyboardWithName:@"HelpStackStoryboard" bundle:[NSBundle mainBundle]];
        UINavigationController *mainNavVC = [helpStoryboard instantiateInitialViewController];
        UIViewController *firstVC = mainNavVC.viewControllers.firstObject;
        firstVC.navigationItem.leftBarButtonItem = nil;
        [self showDetailViewController:mainNavVC sender:self];
      } else {
        [settingsPrimaryTableViewController.tableView
         deselectRowAtIndexPath:NYPLSettingsPrimaryTableViewControllerIndexPathFromSettingsItem(item)
         animated:YES];
        [[HSHelpStack instance] showHelp:self];
      }
      return;
    }
    case NYPLSettingsPrimaryTableViewControllerItemCustomFeedURL:
      return;
  }

  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    [self showDetailViewController:[[UINavigationController alloc]
                                    initWithRootViewController:viewController]
                            sender:self];
  } else {
    [settingsPrimaryTableViewController.tableView
     deselectRowAtIndexPath:NYPLSettingsPrimaryTableViewControllerIndexPathFromSettingsItem(item)
     animated:YES];
    [self showDetailViewController:viewController sender:self];
  }
}

@end
