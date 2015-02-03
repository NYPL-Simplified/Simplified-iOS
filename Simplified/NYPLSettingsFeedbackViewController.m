#import "NYPLSettingsFeedbackViewController.h"

@implementation NYPLSettingsFeedbackViewController

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.title = NSLocalizedString(@"Feedback", nil);
  
  return self;
}

- (void)viewDidLoad
{
  self.view.backgroundColor = [UIColor redColor];
}

@end
