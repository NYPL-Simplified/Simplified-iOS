@import QuartzCore.QuartzCore;

#import "NYPLConfiguration.h"

#import "NYPLSettingsCredentialView.h"

@implementation NYPLSettingsCredentialView

- (instancetype)initWithCoder:(NSCoder *const)decoder
{
  self = [super initWithCoder:decoder];
  if(!self) return nil;

  self.barcodeLabel.text = NSLocalizedString(@"NYPLSettingsCredentialViewBarcode", nil);
  self.PINLabel.text = NSLocalizedString(@"NYPLSettingsCredentialViewPIN", nil);
  [self.scanButton setTitle:NSLocalizedString(@"NYPLSettingsCredentialViewScanBarcode", nil)
                   forState:UIControlStateNormal];
  
  return self;
}

@end