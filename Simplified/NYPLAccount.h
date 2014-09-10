static NSString *const NYPLAccountDidChangeNotification = @"NYPLAccountDidChangeNotification";

@interface NYPLAccount : NSObject

@property (atomic, readonly) NSString *barcode; // nil if not logged in
@property (atomic, readonly) NSString *PIN;     // nil if not logged in

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (instancetype)sharedAccount;

// Neither |barcode| nor |pin| may be null.
- (void)setBarcode:(NSString *)barcode PIN:(NSString *)PIN;

- (BOOL)hasBarcodeAndPIN;

- (void)removeBarcodeAndPIN;

@end
