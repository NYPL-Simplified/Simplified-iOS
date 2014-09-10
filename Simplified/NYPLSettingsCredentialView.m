#import "NYPLSettingsCredentialView.h"

@implementation NYPLSettingsCredentialView

- (instancetype)initWithCoder:(NSCoder *const)decoder
{
  self = [super initWithCoder:decoder];
  if(!self) return nil;

  self.barcodeLabel.text = NSLocalizedString(@"SettingsCredentialViewBarcode", nil);
  self.PINLabel.text = NSLocalizedString(@"SettingsCredentialViewPIN", nil);
  [self.scanButton setTitle:NSLocalizedString(@"SettingsCredentialViewScanBarcode", nil)
                   forState:UIControlStateNormal];
  
  return self;
}

@end