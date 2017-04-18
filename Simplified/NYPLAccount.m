#import "NYPLKeychain.h"

#import "NYPLAccount.h"
#import "NYPLSettings.h"
#import "SimplyE-Swift.h"

NSString * authorizationIdentifierKey = @"NYPLAccountAuthorization";
NSString * barcodeKey = @"NYPLAccountBarcode";
NSString * PINKey = @"NYPLAccountPIN";
NSString * adobeTokenKey = @"NYPLAccountAdobeTokenKey";
NSString * licensorKey = @"NYPLAccountLicensorKey";
NSString * patronKey = @"NYPLAccountPatronKey";
NSString * authTokenKey = @"NYPLAccountAuthTokenKey";
NSString * adobeVendorKey = @"NYPLAccountAdobeVendorKey";
NSString * providerKey = @"NYPLAccountProviderKey";
NSString * userIDKey = @"NYPLAccountUserIDKey";
NSString * deviceIDKey = @"NYPLAccountDeviceIDKey";


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
  
  NSInteger library = [[NYPLSettings sharedSettings] currentAccountIdentifier];

  if (library != 0)
  {
    barcodeKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountBarcode",[@(library) stringValue]];
    authorizationIdentifierKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountAuthorization",[@(library) stringValue]];
    PINKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountPIN",[@(library) stringValue]];
    adobeTokenKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountAdobeTokenKey",[@(library) stringValue]];
    patronKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountPatronKey",[@(library) stringValue]];
    authTokenKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountAuthTokenKey",[@(library) stringValue]];
    adobeVendorKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountAdobeVendorKey",[@(library) stringValue]];
    providerKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountProviderKey",[@(library) stringValue]];
    userIDKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountUserIDKey",[@(library) stringValue]];
    deviceIDKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountDeviceIDKey",[@(library) stringValue]];
    licensorKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountLicensorKey",[@(library) stringValue]];

  }
  else
  {
    barcodeKey = @"NYPLAccountBarcode";
    authorizationIdentifierKey = @"NYPLAccountAuthorization";
    PINKey = @"NYPLAccountPIN";
    adobeTokenKey = @"NYPLAccountAdobeTokenKey";
    patronKey = @"NYPLAccountPatronKey";
    authTokenKey = @"NYPLAccountAuthTokenKey";
    adobeVendorKey = @"NYPLAccountAdobeVendorKey";
    providerKey = @"NYPLAccountProviderKey";
    userIDKey = @"NYPLAccountUserIDKey";
    deviceIDKey = @"NYPLAccountDeviceIDKey";
    licensorKey = @"NYPLAccountLicensorKey";


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
  
  
  if (account != 0)
  {
    barcodeKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountBarcode",[@(account) stringValue]];
    authorizationIdentifierKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountAuthorization",[@(account) stringValue]];
    PINKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountPIN",[@(account) stringValue]];
    adobeTokenKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountAdobeTokenKey",[@(account) stringValue]];
    patronKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountPatronKey",[@(account) stringValue]];
    authTokenKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountAuthTokenKey",[@(account) stringValue]];
    adobeVendorKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountAdobeVendorKey",[@(account) stringValue]];
    providerKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountProviderKey",[@(account) stringValue]];
    userIDKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountUserIDKey",[@(account) stringValue]];
    deviceIDKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountDeviceIDKey",[@(account) stringValue]];
    licensorKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountLicensorKey",[@(account) stringValue]];

  }
  else
  {
    barcodeKey = @"NYPLAccountBarcode";
    authorizationIdentifierKey = @"NYPLAccountAuthorization";
    PINKey = @"NYPLAccountPIN";
    adobeTokenKey = @"NYPLAccountAdobeTokenKey";
    patronKey = @"NYPLAccountPatronKey";
    authTokenKey = @"NYPLAccountAuthTokenKey";
    adobeVendorKey = @"NYPLAccountAdobeVendorKey";
    providerKey = @"NYPLAccountProviderKey";
    userIDKey = @"NYPLAccountUserIDKey";
    deviceIDKey = @"NYPLAccountDeviceIDKey";
    licensorKey = @"NYPLAccountLicensorKey";

  }


  return sharedAccount;
}

- (BOOL)hasCredentials
{
  if (self.hasAuthToken || self.hasBarcodeAndPIN) return YES;
  if (!self.hasAuthToken && !self.hasBarcodeAndPIN) return NO;
  
  @throw NSInternalInconsistencyException;
}

- (BOOL)hasBarcodeAndPIN
{
  if(self.barcode && self.PIN) return YES;
  
  if(!self.barcode && !self.PIN) return NO;
  
  @throw NSInternalInconsistencyException;
}

- (BOOL)hasAuthToken
{
  if(self.authToken) return YES;
  
  if(!self.authToken) return NO;
  
  @throw NSInternalInconsistencyException;
}
- (BOOL)hasAdobeToken
{
  if(self.adobeToken) return YES;
  
  if(!self.adobeToken) return NO;
  
  @throw NSInternalInconsistencyException;
}
- (BOOL)hasLicensor
{
  if(self.licensor) return YES;
  
  if(!self.licensor) return NO;
  
  @throw NSInternalInconsistencyException;
}
- (NSString *)authorizationIdentifier
{
  return [[NYPLKeychain sharedKeychain] objectForKey:authorizationIdentifierKey];
}

- (NSString *)barcode
{
  return [[NYPLKeychain sharedKeychain] objectForKey:barcodeKey];
}

- (NSString *)PIN
{
  return [[NYPLKeychain sharedKeychain] objectForKey:PINKey];
}

- (NSString *)adobeVendor
{
  return [[NYPLKeychain sharedKeychain] objectForKey:adobeVendorKey];
}

- (NSString *)adobeToken
{
  return [[NYPLKeychain sharedKeychain] objectForKey:adobeTokenKey];
}

- (NSDictionary *)licensor
{
  return [[NYPLKeychain sharedKeychain] objectForKey:licensorKey];
}

- (NSDictionary *)patron
{
  return [[NYPLKeychain sharedKeychain] objectForKey:patronKey];
}
- (NSString *)patronFullName
{
  return [NSString stringWithFormat:@"%@ %@ %@", self.patron[@"name"][@"first"], self.patron[@"name"][@"middle"],self.patron[@"name"][@"last"]];
}


- (NSString *)authToken
{
  return [[NYPLKeychain sharedKeychain] objectForKey:authTokenKey];
}
- (NSString *)provider
{
  return [[NYPLKeychain sharedKeychain] objectForKey:providerKey];
}
- (NSString *)userID
{
  return [[NYPLKeychain sharedKeychain] objectForKey:userIDKey];
}
- (NSString *)deviceID
{
  return [[NYPLKeychain sharedKeychain] objectForKey:deviceIDKey];
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

- (void)setAdobeToken:(NSString *)adobeToken patron:(NSDictionary *)patron
{
  if(!(adobeToken && patron)) {
    @throw NSInvalidArgumentException;
  }
  
  [[NYPLKeychain sharedKeychain] setObject:adobeToken forKey:adobeTokenKey];
  [[NYPLKeychain sharedKeychain] setObject:patron forKey:patronKey];
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLAccountDidChangeNotification
   object:self];

}
- (void)setAdobeToken:(NSString *)adobeToken
{
  if(!(adobeToken)) {
    @throw NSInvalidArgumentException;
  }

  [[NYPLKeychain sharedKeychain] setObject:adobeToken forKey:adobeTokenKey];
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLAccountDidChangeNotification
   object:self];

}
- (void)setLicensor:(NSDictionary *)licensor
{
  if(!(licensor)) {
    @throw NSInvalidArgumentException;
  }
  
  [[NYPLKeychain sharedKeychain] setObject:licensor forKey:licensorKey];
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLAccountDidChangeNotification
   object:self];
  
}
- (void)setAuthorizationIdentifier:(NSString *)identifier
{
  if(!(identifier)) {
    @throw NSInvalidArgumentException;
  }
  
  [[NYPLKeychain sharedKeychain] setObject:identifier forKey:authorizationIdentifierKey];
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLAccountDidChangeNotification
   object:self];
  
}
- (void)setPatron:(NSDictionary *)patron
{
  if(!(patron)) {
    @throw NSInvalidArgumentException;
  }

  [[NYPLKeychain sharedKeychain] setObject:patron forKey:patronKey];
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLAccountDidChangeNotification
   object:self];

}
- (void)setAuthToken:(NSString *)authToken
{
  if(!(authToken)) {
    @throw NSInvalidArgumentException;
  }

  [[NYPLKeychain sharedKeychain] setObject:authToken forKey:authTokenKey];
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLAccountDidChangeNotification
   object:self];
}

- (void)setAdobeVendor:(NSString *)adobeVendor
{
  if(!(adobeVendor)) {
    @throw NSInvalidArgumentException;
  }
  
  [[NYPLKeychain sharedKeychain] setObject:adobeVendor forKey:adobeVendorKey];
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLAccountDidChangeNotification
   object:self];
}

- (void)setProvider:(NSString *)provider
{
  if(!(provider)) {
    @throw NSInvalidArgumentException;
  }
  
  [[NYPLKeychain sharedKeychain] setObject:provider forKey:providerKey];
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLAccountDidChangeNotification
   object:self];
}
- (void)setUserID:(NSString *)userID
{
  if(!(userID)) {
    @throw NSInvalidArgumentException;
  }
  
  [[NYPLKeychain sharedKeychain] setObject:userID forKey:userIDKey];
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLAccountDidChangeNotification
   object:self];
}
- (void)setDeviceID:(NSString *)deviceID
{
  if(!(deviceID)) {
    @throw NSInvalidArgumentException;
  }
  
  [[NYPLKeychain sharedKeychain] setObject:deviceID forKey:deviceIDKey];
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLAccountDidChangeNotification
   object:self];
}

- (void)removeAll
{
  [[NYPLKeychain sharedKeychain] removeObjectForKey:barcodeKey];
  [[NYPLKeychain sharedKeychain] removeObjectForKey:authorizationIdentifierKey];
  [[NYPLKeychain sharedKeychain] removeObjectForKey:PINKey];
  [[NYPLKeychain sharedKeychain] removeObjectForKey:adobeTokenKey];
  [[NYPLKeychain sharedKeychain] removeObjectForKey:patronKey];
  [[NYPLKeychain sharedKeychain] removeObjectForKey:authTokenKey];
  [[NYPLKeychain sharedKeychain] removeObjectForKey:adobeVendorKey];
  [[NYPLKeychain sharedKeychain] removeObjectForKey:providerKey];
  [[NYPLKeychain sharedKeychain] removeObjectForKey:userIDKey];
  [[NYPLKeychain sharedKeychain] removeObjectForKey:deviceIDKey];
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLAccountDidChangeNotification
   object:self];
}


- (void)removeObject:(NSString *const)key
{
  [[NYPLKeychain sharedKeychain] removeObjectForKey:key];
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLAccountDidChangeNotification
   object:self];
}

- (void)removeBarcodeAndPIN
{
  [[NYPLKeychain sharedKeychain] removeObjectForKey:barcodeKey];
  [[NYPLKeychain sharedKeychain] removeObjectForKey:authorizationIdentifierKey];
  [[NYPLKeychain sharedKeychain] removeObjectForKey:PINKey];
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:NYPLAccountDidChangeNotification
   object:self];
}

@end
