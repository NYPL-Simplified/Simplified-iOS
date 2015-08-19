#import "NYPLSettingsAccountViewController.h"
#import "NYPLSettingsCreditsViewController.h"
#import "NYPLSettingsFeedbackViewController.h"
#import "NYPLSettingsPrimaryNavigationController.h"
#import "NYPLSettingsPrimaryTableViewController.h"
#import "NYPLSettingsEULAViewController.h"
#import "NYPLSettingsPrivacyPolicyViewController.h"
#import "NYPLSettings.h"
#import "NYPLBook.h"
#import "NYPLMyBooksDownloadCenter.h"

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
    case NYPLSettingsPrimaryTableViewControllerItemAccount:
      viewController = [[NYPLSettingsAccountViewController alloc] init];
      break;
    case NYPLSettingsPrimaryTableViewControllerItemCredits:
      viewController = [[NYPLSettingsCreditsViewController alloc] init];
      break;
    case NYPLSettingsPrimaryTableViewControllerItemFeedback:
      viewController = [[NYPLSettingsFeedbackViewController alloc] init];
      break;
    case NYPLSettingsPrimaryTableViewControllerItemEULA:
      viewController = [[NYPLSettingsEULAViewController alloc] init];
      break;
    case NYPLSettingsPrimaryTableViewControllerItemPrivacyPolicy:
      viewController = [[NYPLSettingsPrivacyPolicyViewController alloc] init];
      break;
      case NYPLSettingsPrimaryTableViewControllerItemRestorePreloadedContent:
      [self restorePreloadedContent];
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

-(void) restorePreloadedContent {
  @synchronized (self) {
    NSArray *booksToRestorePreload = [[NYPLSettings sharedSettings] booksToPreloadCurrentlyMissing];
    for (NYPLBook *book in booksToRestorePreload) {
      [[NYPLMyBooksDownloadCenter sharedDownloadCenter] startDownloadForPreloadedBook:book];
    }
    [[NYPLSettings sharedSettings] setPreloadContentCompleted:YES];
    
    NSString *alertMessage;
    if (booksToRestorePreload.count > 0) {
      alertMessage = NSLocalizedString(@"PreloadedContentRestoredMessage", nil);
    }
    else {
      alertMessage = NSLocalizedString(@"PreloadedContentNothingRestoredMessage", nil);
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"PreloadedContent", nil)
                                                                             message:alertMessage
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil];
    [alertController addAction:okAction];
    
    [self presentViewController:alertController
                       animated:NO
                     completion:nil];

  }
}

@end
