@interface NYPLAccount : NSObject

@property (atomic, readonly) NSString *barcode; // nil if not logged in
@property (atomic, readonly) NSString *PIN;     // nil if not logged in

+ (instancetype)sharedAccount;

// Neither |barcode| nor |pin| may be null.
- (void)setBarcode:(NSString *)barcode PIN:(NSString *)PIN;

- (BOOL)hasBarcodeAndPIN;

- (void)removeBarcodeAndPIN;

@end
