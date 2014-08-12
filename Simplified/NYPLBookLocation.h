@interface NYPLBookLocation : NSObject

@property (nonatomic, readonly) NSString *CFI; // nilable
@property (nonatomic, readonly) NSString *idref;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

// designated initializer
- (instancetype)initWithCFI:(NSString *)CFI idref:(NSString *)idref;

// designated initializer
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
