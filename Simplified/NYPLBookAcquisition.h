@interface NYPLBookAcquisition : NSObject

@property (nonatomic, readonly) NSURL *borrow; // nilable
@property (nonatomic, readonly) NSURL *generic; // nilable
@property (nonatomic, readonly) NSURL *openAccess; // nilable
@property (nonatomic, readonly) NSURL *sample; // nilable

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

// designated initializer
- (instancetype)initWithBorrow:(NSURL *)borrow
                       generic:(NSURL *)generic
                    openAccess:(NSURL *)openAccess
                        sample:(NSURL *)sample;

// designated initializer
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)dictionaryRepresentation;

// This may return nil if no means of acquisition is available.
- (NSURL *)preferredURL;

@end
