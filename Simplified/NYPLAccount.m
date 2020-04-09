//#import "NYPLKeychain.h"
//
//#import "NYPLAccount.h"
//
//#import "SimplyE-Swift.h"
//
//NSString * authorizationIdentifierKey = @"NYPLAccountAuthorization";
//NSString * barcodeKey = @"NYPLAccountBarcode";
//NSString * PINKey = @"NYPLAccountPIN";
//NSString * adobeTokenKey = @"NYPLAccountAdobeTokenKey";
//NSString * licensorKey = @"NYPLAccountLicensorKey";
//NSString * patronKey = @"NYPLAccountPatronKey";
//NSString * authTokenKey = @"NYPLAccountAuthTokenKey";
//NSString * adobeVendorKey = @"NYPLAccountAdobeVendorKey";
//NSString * providerKey = @"NYPLAccountProviderKey";
//NSString * userIDKey = @"NYPLAccountUserIDKey";
//NSString * deviceIDKey = @"NYPLAccountDeviceIDKey";
//
//
//@implementation NYPLAccount
//
//+ (instancetype)sharedAccount
//{
//  NSString *library = [AccountsManager shared].currentAccount.uuid;
//  return [self sharedAccount:library];
//}
//
//+ (instancetype)sharedAccount:(NSString *)libraryUUID
//{
//  static NYPLAccount *sharedAccount = nil;
//  
//  if (sharedAccount == nil) {
//    sharedAccount = [[self alloc] init];
//    if(!sharedAccount) {
//      NYPLLOG(@"Failed to create shared account.");
//    }
//  }
//  
//  if (![libraryUUID isEqualToString:[AccountsManager NYPLAccountUUIDs][0]])
//  {
//    barcodeKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountBarcode", libraryUUID];
//    authorizationIdentifierKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountAuthorization", libraryUUID];
//    PINKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountPIN", libraryUUID];
//    adobeTokenKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountAdobeTokenKey", libraryUUID];
//    patronKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountPatronKey", libraryUUID];
//    authTokenKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountAuthTokenKey", libraryUUID];
//    adobeVendorKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountAdobeVendorKey", libraryUUID];
//    providerKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountProviderKey", libraryUUID];
//    userIDKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountUserIDKey", libraryUUID];
//    deviceIDKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountDeviceIDKey", libraryUUID];
//    licensorKey = [NSString stringWithFormat:@"%@_%@",@"NYPLAccountLicensorKey", libraryUUID];
//  }
//  else
//  {
//    barcodeKey = @"NYPLAccountBarcode";
//    authorizationIdentifierKey = @"NYPLAccountAuthorization";
//    PINKey = @"NYPLAccountPIN";
//    adobeTokenKey = @"NYPLAccountAdobeTokenKey";
//    patronKey = @"NYPLAccountPatronKey";
//    authTokenKey = @"NYPLAccountAuthTokenKey";
//    adobeVendorKey = @"NYPLAccountAdobeVendorKey";
//    providerKey = @"NYPLAccountProviderKey";
//    userIDKey = @"NYPLAccountUserIDKey";
//    deviceIDKey = @"NYPLAccountDeviceIDKey";
//    licensorKey = @"NYPLAccountLicensorKey";
//  }
//
//  return sharedAccount;
//}
//
//- (BOOL)hasCredentials
//{
//  return self.hasAuthToken || self.hasBarcodeAndPIN;
//}
//
//- (BOOL)hasBarcodeAndPIN
//{
//  return self.barcode != nil && self.PIN != nil;
//}
//
//- (BOOL)hasAuthToken
//{
//  return self.authToken != nil;
//}
//
//- (BOOL)hasAdobeToken
//{
//  return self.adobeToken != nil;
//}
//
//- (BOOL)hasLicensor
//{
//  return self.licensor != nil;
//}
//
//- (NSString *)authorizationIdentifier
//{
//  return [[NYPLKeychain sharedKeychain] objectForKey:authorizationIdentifierKey];
//}
//
//- (NSString *)barcode
//{
//  return [[NYPLKeychain sharedKeychain] objectForKey:barcodeKey];
//}
//
//- (NSString *)PIN
//{
//  return [[NYPLKeychain sharedKeychain] objectForKey:PINKey];
//}
//
//- (NSString *)adobeVendor
//{
//  return [[NYPLKeychain sharedKeychain] objectForKey:adobeVendorKey];
//}
//
//- (NSString *)adobeToken
//{
//  return [[NYPLKeychain sharedKeychain] objectForKey:adobeTokenKey];
//}
//
//- (NSDictionary *)licensor
//{
//  return [[NYPLKeychain sharedKeychain] objectForKey:licensorKey];
//}
//
//- (NSDictionary *)patron
//{
//  return [[NYPLKeychain sharedKeychain] objectForKey:patronKey];
//}
//
//- (NSString *)patronFullName
//{
//  return [NSString stringWithFormat:@"%@ %@ %@", self.patron[@"name"][@"first"], self.patron[@"name"][@"middle"],self.patron[@"name"][@"last"]];
//}
//
//- (NSString *)authToken
//{
//  return [[NYPLKeychain sharedKeychain] objectForKey:authTokenKey];
//}
//
//- (NSString *)provider
//{
//  return [[NYPLKeychain sharedKeychain] objectForKey:providerKey];
//}
//
//- (NSString *)userID
//{
//  return [[NYPLKeychain sharedKeychain] objectForKey:userIDKey];
//}
//
//- (NSString *)deviceID
//{
//  return [[NYPLKeychain sharedKeychain] objectForKey:deviceIDKey];
//}
//
//- (void)setBarcode:(NSString *const)barcode PIN:(NSString *)PIN
//{
//  if(!(barcode && PIN)) {
//    @throw NSInvalidArgumentException;
//  }
//
//  [[NYPLKeychain sharedKeychain] setObject:barcode forKey:barcodeKey];
//  [[NYPLKeychain sharedKeychain] setObject:PIN forKey:PINKey];
//
//  // make sure to set the barcode related to the current account (aka library)
//  // not the one we just signed in to, because we could have signed in into
//  // library A, but still browsing the catalog of library B.
//  [NYPLErrorLogger setUserID:[[NYPLAccount sharedAccount] barcode]];
//  
//  [[NSNotificationCenter defaultCenter]
//   postNotificationName:NYPLAccountDidChangeNotification
//   object:self];
//}
//
//- (void)setAdobeToken:(NSString *)adobeToken patron:(NSDictionary *)patron
//{
//  if(!(adobeToken && patron)) {
//    @throw NSInvalidArgumentException;
//  }
//  
//  [[NYPLKeychain sharedKeychain] setObject:adobeToken forKey:adobeTokenKey];
//  [[NYPLKeychain sharedKeychain] setObject:patron forKey:patronKey];
//  
//  [[NSNotificationCenter defaultCenter]
//   postNotificationName:NYPLAccountDidChangeNotification
//   object:self];
//
//}
//- (void)setAdobeToken:(NSString *)adobeToken
//{
//  if(!(adobeToken)) {
//    @throw NSInvalidArgumentException;
//  }
//
//  [[NYPLKeychain sharedKeychain] setObject:adobeToken forKey:adobeTokenKey];
//  
//  [[NSNotificationCenter defaultCenter]
//   postNotificationName:NYPLAccountDidChangeNotification
//   object:self];
//
//}
//- (void)setLicensor:(NSDictionary *)licensor
//{
//  if(!(licensor)) {
//    @throw NSInvalidArgumentException;
//  }
//  
//  [[NYPLKeychain sharedKeychain] setObject:licensor forKey:licensorKey];
//}
//- (void)setAuthorizationIdentifier:(NSString *)identifier
//{
//  if(!(identifier)) {
//    @throw NSInvalidArgumentException;
//  }
//  
//  [[NYPLKeychain sharedKeychain] setObject:identifier forKey:authorizationIdentifierKey];
//}
//- (void)setPatron:(NSDictionary *)patron
//{
//  if(!(patron)) {
//    @throw NSInvalidArgumentException;
//  }
//
//  [[NYPLKeychain sharedKeychain] setObject:patron forKey:patronKey];
//  
//  [[NSNotificationCenter defaultCenter]
//   postNotificationName:NYPLAccountDidChangeNotification
//   object:self];
//
//}
//- (void)setAuthToken:(NSString *)authToken
//{
//  if(!(authToken)) {
//    @throw NSInvalidArgumentException;
//  }
//
//  [[NYPLKeychain sharedKeychain] setObject:authToken forKey:authTokenKey];
//  
//  [[NSNotificationCenter defaultCenter]
//   postNotificationName:NYPLAccountDidChangeNotification
//   object:self];
//}
//
//- (void)setAdobeVendor:(NSString *)adobeVendor
//{
//  if(!(adobeVendor)) {
//    @throw NSInvalidArgumentException;
//  }
//  
//  [[NYPLKeychain sharedKeychain] setObject:adobeVendor forKey:adobeVendorKey];
//  
//  [[NSNotificationCenter defaultCenter]
//   postNotificationName:NYPLAccountDidChangeNotification
//   object:self];
//}
//
//- (void)setProvider:(NSString *)provider
//{
//  if(!(provider)) {
//    @throw NSInvalidArgumentException;
//  }
//  
//  [[NYPLKeychain sharedKeychain] setObject:provider forKey:providerKey];
//  
//  [[NSNotificationCenter defaultCenter]
//   postNotificationName:NYPLAccountDidChangeNotification
//   object:self];
//}
//
//- (void)setUserID:(NSString *)userID
//{
//  if(!(userID)) {
//    @throw NSInvalidArgumentException;
//  }
//
//  [[NYPLKeychain sharedKeychain] setObject:userID forKey:userIDKey];
//  
//  [[NSNotificationCenter defaultCenter]
//   postNotificationName:NYPLAccountDidChangeNotification
//   object:self];
//}
//
//- (void)setDeviceID:(NSString *)deviceID
//{
//  if(!(deviceID)) {
//    @throw NSInvalidArgumentException;
//  }
//  
//  [[NYPLKeychain sharedKeychain] setObject:deviceID forKey:deviceIDKey];
//  
//  [[NSNotificationCenter defaultCenter]
//   postNotificationName:NYPLAccountDidChangeNotification
//   object:self];
//}
//
//- (void)removeAll
//{
//  [[NYPLKeychain sharedKeychain] removeObjectForKey:adobeTokenKey];
//  [[NYPLKeychain sharedKeychain] removeObjectForKey:patronKey];
//  [[NYPLKeychain sharedKeychain] removeObjectForKey:authTokenKey];
//  [[NYPLKeychain sharedKeychain] removeObjectForKey:adobeVendorKey];
//  [[NYPLKeychain sharedKeychain] removeObjectForKey:providerKey];
//  [[NYPLKeychain sharedKeychain] removeObjectForKey:userIDKey];
//  [[NYPLKeychain sharedKeychain] removeObjectForKey:deviceIDKey];
//
//  [self removeBarcodeAndPIN];
//}
//
//- (void)removeBarcodeAndPIN
//{
//  [[NYPLKeychain sharedKeychain] removeObjectForKey:barcodeKey];
//  [[NYPLKeychain sharedKeychain] removeObjectForKey:authorizationIdentifierKey];
//  [[NYPLKeychain sharedKeychain] removeObjectForKey:PINKey];
//
//  [[NSNotificationCenter defaultCenter]
//   postNotificationName:NYPLAccountDidChangeNotification
//   object:self];
//}
//
//@end
