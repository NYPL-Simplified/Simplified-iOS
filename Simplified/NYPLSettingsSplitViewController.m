#import "HSHelpStack.h"
#import "NYPLSettingsAboutViewController.h"
#import "NYPLSettingsAccountViewController.h"
#import "NYPLSettingsCreditsViewController.h"
#import "NYPLSettingsFeedbackViewController.h"
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
  
  self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemMore tag:0];
  self.title = NSLocalizedString(@"More", nil);
  
  self.primaryNavigationController = [[NYPLSettingsPrimaryNavigationController alloc] init];
  self.primaryNavigationController.primaryTableViewController.delegate = self;
  
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    self.viewControllers = @[self.primaryNavigationController,
                             [[UINavigationController alloc] initWithRootViewController:
                              [[NYPLSettingsAccountViewController alloc] init]]];
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
  switch(item) {
    case NYPLSettingsPrimaryTableViewControllerItemAbout:
      viewController = [[NYPLSettingsAboutViewController alloc] init];
      break;
    case NYPLSettingsPrimaryTableViewControllerItemAccount:
      viewController = [[NYPLSettingsAccountViewController alloc] init];
      break;
    case NYPLSettingsPrimaryTableViewControllerItemCredits:
      viewController = [[NYPLSettingsCreditsViewController alloc] init];
      break;
    case NYPLSettingsPrimaryTableViewControllerItemEULA:
      viewController = [[NYPLSettingsEULAViewController alloc] init];
      break;
    case NYPLSettingsPrimaryTableViewControllerItemPrivacyPolicy:
      viewController = [[BundledHTMLViewController alloc]
                        initWithFileURL:[[NSBundle mainBundle]
                                         URLForResource:@"privacy-policy"
                                         withExtension:@"html"]
                        title:NSLocalizedString(@"PrivacyPolicy", nil)];
      break;
    case NYPLSettingsPrimaryTableViewControllerItemHelpStack:
      [[HSHelpStack instance] showHelp:self];
      break;
    case NYPLSettingsPrimaryTableViewControllerItemCustomFeedURL:
      break;
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
