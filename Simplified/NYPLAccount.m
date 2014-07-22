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

- (BOOL)loggedIn
{
  return !!self.barcode && !!self.PIN;
}

- (NSString *)barcode {
  return [[NYPLKeychain sharedKeychain] objectForKey:barcodeKey];
}

- (void)setBarcode:(NSString *const)barcode
{
  [[NYPLKeychain sharedKeychain] setObject:barcode forKey:barcodeKey];
}

- (NSString *)PIN {
  return [[NYPLKeychain sharedKeychain] objectForKey:PINKey];
}

- (void)setPIN:(NSString *const)PIN {
  [[NYPLKeychain sharedKeychain] setObject:PIN forKey:PINKey];
}

@end
