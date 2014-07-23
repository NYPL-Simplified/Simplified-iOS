#import "NYPLAccount.h"

#import "NYPLSettingsViewController.h"

@interface NYPLSettingsViewController () <UITextFieldDelegate>

@property (nonatomic) UILabel *barcodeLabel;
@property (nonatomic) UILabel *PINLabel;

@end

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
  self.view.backgroundColor = [UIColor lightGrayColor];
  
  self.barcodeLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 69, 310, 31)];
  [self.view addSubview:self.barcodeLabel];
  
  self.PINLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 69 + 31 + 5, 310, 31)];
  [self.view addSubview:self.PINLabel];
}

- (void)viewWillAppear:(__attribute__((unused)) BOOL)animated
{
  NSString *const barcode = [NYPLAccount sharedAccount].barcode;
  if(barcode) {
    self.barcodeLabel.text = barcode;
  }
  
  NSString *const PIN = [NYPLAccount sharedAccount].PIN;
  if(PIN) {
    self.PINLabel.text = PIN;
  }
}

@end
