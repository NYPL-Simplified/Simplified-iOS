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
  
  NSString *library = [[NYPLSettings sharedSettings] currentLibrary];

  if (![library isEqualToString:[@(NYPLChosenLibraryNYPL) stringValue]])
  {
    barcodeKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountBarcode",library];
    PINKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountPIN",library];
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
