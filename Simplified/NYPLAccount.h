static NSString *const NYPLAccountDidChangeNotification = @"NYPLAccountDidChangeNotification";
static NSString *const NYPLAccountLoginDidChangeNotification =
@"NYPLAccountLoginDidChangeNotification";

@interface NYPLAccount : NSObject

@property (atomic, readonly) NSString *barcode; // nil if not logged in
@property (atomic, readonly) NSString *authorizationIdentifier;
@property (atomic, readonly) NSString *PIN;     // nil if not logged in
@property (atomic, readonly) NSString *deviceID;     // nil if not logged in
@property (atomic, readonly) NSString *userID;     // nil if not logged in
@property (atomic, readonly) NSString *adobeVendor; // nil if not logged in
@property (atomic, readonly) NSString *provider; // nil if not logged in
@property (atomic, readonly) NSDictionary *patron;     // nil if not logged in
@property (atomic, readonly) NSString *patronFullName;     // nil if not logged in
@property (atomic, readonly) NSString *authToken;     // nil if not logged in
@property (atomic, readonly) NSString *adobeToken; // nil if not logged in



+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (instancetype)sharedAccount;

+ (instancetype)sharedAccount:(NSInteger)account;

// Neither |barcode| nor |pin| may be null.
- (void)setBarcode:(NSString *)barcode PIN:(NSString *)PIN;

- (void)setAdobeToken:(NSString *)adobeToken patron:(NSDictionary *)patron;

- (void)setAdobeVendor:(NSString *)adobeVendor;

- (void)setAdobeToken:(NSString *)adobeToken;

- (void)setLicensor:(NSDictionary *)licensor;

- (void)setAuthorizationIdentifier:(NSString *)identifier;

- (void)setPatron:(NSDictionary *)patron;

- (void)setAuthToken:(NSString *)authToken;

- (void)setProvider:(NSString *)provider;
- (void)setUserID:(NSString *)userID;
- (void)setDeviceID:(NSString *)deviceID;

- (BOOL)hasAuthToken;

- (BOOL)hasAdobeToken;

- (BOOL)hasLicensor;

- (BOOL)hasBarcodeAndPIN;

- (BOOL)hasCredentials;

- (void)removeBarcodeAndPIN;

- (void)removeAll;

- (void)removeObject:(NSString *const)key;

- (NSDictionary *)licensor;

@end
