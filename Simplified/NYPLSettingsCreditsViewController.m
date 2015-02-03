#import "NYPLSettingsCreditsViewController.h"

@implementation NYPLSettingsCreditsViewController

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.title = NSLocalizedString(@"CreditsAndAcknowledgements", nil);
  
  return self;
}

- (void)viewDidLoad
{
  self.view.backgroundColor = [UIColor greenColor];
}

@end
