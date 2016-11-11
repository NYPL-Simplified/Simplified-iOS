#import "NYPLKeychain.h"

#import "NYPLAccount.h"
#import "NYPLSettings.h"
#import "SimplyE-Swift.h"

NSString * barcodeKey = @"NYPLAccountBarcode";
NSString * PINKey = @"NYPLAccountPIN";

@implementation NYPLAccount

+ (instancetype)sharedAccount
{
  static NYPLAccount *sharedAccount = nil;
  
  if (sharedAccount == nil) {
    sharedAccount = [[self alloc] init];
    if(!sharedAccount) {
      NYPLLOG(@"Failed to create shared account.");
    }
  }
  
  NYPLUserAccountType library = [[NYPLSettings sharedSettings] currentAccountIdentifier];

  if (library != NYPLUserAccountTypeNYPL)
  {
    barcodeKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountBarcode",[@(library) stringValue]];
    PINKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountPIN",[@(library) stringValue]];
  }
  else
  {
    barcodeKey = @"NYPLAccountBarcode";
    PINKey = @"NYPLAccountPIN";
  }
  return sharedAccount;
}

+ (instancetype)sharedAccount:(NSInteger)account
{
  static NYPLAccount *sharedAccount = nil;
  
  if (sharedAccount == nil) {
    sharedAccount = [[self alloc] init];
    if(!sharedAccount) {
      NYPLLOG(@"Failed to create shared account.");
    }
  }
  
  
  if (account != NYPLUserAccountTypeNYPL)
  {
    barcodeKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountBarcode",[@(account) stringValue]];
    PINKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountPIN",[@(account) stringValue]];
  }
  else
  {
    barcodeKey = @"NYPLAccountBarcode";
    PINKey = @"NYPLAccountPIN";
  }


  return sharedAccount;
}
- (BOOL)hasBarcodeAndPIN
{
  if(self.barcode && self.PIN) return YES;
  
  if(!self.barcode && !self.PIN) return NO;
  
  @throw NSInternalInconsistencyException;
}

- (NSString *)barcode
{
  return [[NYPLKeychain sharedKeychain] objectForKey:barcodeKey];
}

- (NSString *)PIN
{
  return [[NYPLKeychain sharedKeychain] objectForKey:PINKey];
}

- (void)setBarcode:(NSString *const)barcode PIN:(NSString *)PIN
{
  if(!(barcode && PIN)) {
    @throw NSInvalidArgumentException;
  }
  
  [[NYPLKeychain sharedKeychain] setObject:barcode forKey:barcodeKey];
  [[NYPLKeychain sharedKeychain] setObject:PIN forKey:PINKey];
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLAccountDidChangeNotification
   object:self];
}

- (void)removeBarcodeAndPIN
{
  [[NYPLKeychain sharedKeychain] removeObjectForKey:barcodeKey];
  [[NYPLKeychain sharedKeychain] removeObjectForKey:PINKey];
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLAccountDidChangeNotification
   object:self];
}

@end
