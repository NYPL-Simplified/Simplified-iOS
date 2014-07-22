@interface NYPLAccount : NSObject

@property (atomic, readonly) BOOL loggedIn;
@property (atomic) NSString *barcode;
@property (atomic) NSString *PIN;

+ (instancetype)sharedAccount;

@end
