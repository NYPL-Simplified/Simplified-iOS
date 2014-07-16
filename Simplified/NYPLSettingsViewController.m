#import "NYPLSettingsViewController.h"

@interface NYPLSettingsViewController ()

@property (nonatomic) UITextField *barcodeField;
@property (nonatomic) UITextField *PINField;

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
  
  self.barcodeField = [[UITextField alloc] initWithFrame:CGRectMake(5, 69, 310, 31)];
  self.barcodeField.backgroundColor = [UIColor whiteColor];
  self.barcodeField.placeholder = @"Barcode";
  [self.barcodeField addTarget:self
                        action:@selector(fieldsDidChange)
              forControlEvents:UIControlEventEditingDidEnd];
  [self.view addSubview:self.barcodeField];
  
  self.PINField = [[UITextField alloc] initWithFrame:CGRectMake(5, 69 + 31 + 5, 310, 31)];
  self.PINField.backgroundColor = [UIColor whiteColor];
  self.PINField.placeholder = @"PIN";
  [self.PINField addTarget:self
                    action:@selector(fieldsDidChange)
          forControlEvents:UIControlEventEditingDidEnd];
  [self.view addSubview:self.PINField];
}

- (void)viewWillAppear:(__attribute__((unused)) BOOL)animated
{
  
}

#pragma mark -

- (void)fieldsDidChange
{
  NSLog(@"%@ : %@", self.barcodeField.text, self.PINField.text);
}

@end
