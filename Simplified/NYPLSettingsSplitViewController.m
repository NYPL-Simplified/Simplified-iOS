#import "NYPLSettingsPrimaryNavigationController.h"
#import "NYPLSettingsSecondaryNavigationController.h"

#import "NYPLSettingsSplitViewController.h"

@interface NYPLSettingsSplitViewController () <UISplitViewControllerDelegate>

@property (nonatomic) NYPLSettingsPrimaryNavigationController *primaryNavigationController;
@property (nonatomic) NYPLSettingsSecondaryNavigationController *secondaryNavigationController;

@end

@implementation NYPLSettingsSplitViewController

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.delegate = self;
  
  self.title = NSLocalizedString(@"SettingsSplitViewControllerTitle", nil);
  
  self.primaryNavigationController = [[NYPLSettingsPrimaryNavigationController alloc] init];
  self.secondaryNavigationController = [[NYPLSettingsSecondaryNavigationController alloc] init];
  
  self.viewControllers = @[self.primaryNavigationController, self.secondaryNavigationController];
  
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

@end
