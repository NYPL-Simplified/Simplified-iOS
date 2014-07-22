#import "NYPLKeychain.h"
#import "NYPLSettings.h"

#import "NYPLSettingsViewController.h"

@interface NYPLSettingsViewController () <UITextFieldDelegate>

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
  self.barcodeField.delegate = self;
  self.barcodeField.backgroundColor = [UIColor whiteColor];
  self.barcodeField.placeholder = @"Barcode";
  [self.barcodeField addTarget:self
                        action:@selector(fieldsDidChange)
              forControlEvents:UIControlEventEditingDidEnd];
  [self.view addSubview:self.barcodeField];
  
  self.PINField = [[UITextField alloc] initWithFrame:CGRectMake(5, 69 + 31 + 5, 310, 31)];
  self.PINField.delegate = self;
  self.PINField.backgroundColor = [UIColor whiteColor];
  self.PINField.placeholder = @"PIN";
  [self.PINField addTarget:self
                    action:@selector(fieldsDidChange)
          forControlEvents:UIControlEventEditingDidEnd];
  [self.view addSubview:self.PINField];
}

- (void)viewWillAppear:(__attribute__((unused)) BOOL)animated
{
  NSString *const barcode = [[NYPLKeychain sharedKeychain] objectForKey:NYPLSettingsBarcodeKey];
  if(barcode) {
    self.barcodeField.text = barcode;
  }
  
  NSString *const PIN = [[NYPLKeychain sharedKeychain] objectForKey:NYPLSettingsPINKey];
  if(PIN) {
    self.PINField.text = PIN;
  }
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *const)textField {
  if(textField == self.barcodeField) {
    [self.PINField becomeFirstResponder];
  } else {
    [self.PINField resignFirstResponder];
  }
  
  return YES;
}

#pragma mark -

- (void)fieldsDidChange
{
  NSString *const barcode = self.barcodeField.text;
  if(barcode) {
    [[NYPLKeychain sharedKeychain] setObject:[barcode length] > 0 ? barcode : nil
                                      forKey:NYPLSettingsBarcodeKey];
  }
  
  NSString *const PIN = self.PINField.text;
  if(PIN) {
    [[NYPLKeychain sharedKeychain] setObject:[PIN length] > 0 ? PIN : nil
                                      forKey:NYPLSettingsPINKey];
  }
}

@end
