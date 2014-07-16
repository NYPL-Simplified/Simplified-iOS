#import "NYPLSettingsViewController.h"

@implementation NYPLSettingsViewController

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.title = NSLocalizedString(@"SettingsViewControllerTitle", nil);
  
  return self;
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  self.view.backgroundColor = [UIColor whiteColor];
}

@end
