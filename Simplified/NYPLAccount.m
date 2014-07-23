#import "NYPLKeychain.h"

#import "NYPLAccount.h"

static NSString *const barcodeKey = @"NYPLAccountBarcode";
static NSString *const PINKey = @"NYPLAccountPIN";

@implementation NYPLAccount

+ (instancetype)sharedAccount
{
  static dispatch_once_t predicate;
  static NYPLAccount *sharedAccount = nil;
  
  dispatch_once(&predicate, ^{
    sharedAccount = [[self alloc] init];
    if(!sharedAccount) {
      NYPLLOG(@"Failed to create shared account.");
    }
  });
  
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
}

- (void)removeBarcodeAndPIN
{
  [[NYPLKeychain sharedKeychain] removeObjectForKey:barcodeKey];
  [[NYPLKeychain sharedKeychain] removeObjectForKey:PINKey];
}

@end
