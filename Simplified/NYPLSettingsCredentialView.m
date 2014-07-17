#import "NYPLSettingsCredentialView.h"

@interface NYPLSettingsCredentialView ()

@property (nonatomic) UITextField *barcodeField;
@property (nonatomic) UILabel *barcodeLabel;
@property (nonatomic) UIButton *continueButton;
@property (nonatomic) UILabel *messageLabel;
@property (nonatomic) UITextField *PINField;
@property (nonatomic) UILabel *PINLabel;

@end

@implementation NYPLSettingsCredentialView

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.barcodeField = [[UITextField alloc] init];
  self.barcodeLabel = [[UILabel alloc] init];
  self.continueButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  self.messageLabel = [[UILabel alloc] init];
  self.PINField = [[UITextField alloc] init];
  self.PINLabel = [[UILabel alloc] init];
  
  return self;
}

#pragma mark UIView

- (void)layoutSubviews
{

}

@end
