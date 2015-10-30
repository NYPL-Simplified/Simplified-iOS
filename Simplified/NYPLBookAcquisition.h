@interface NYPLBookAcquisition : NSObject

@property (nonatomic, readonly) NSURL *borrow; // nilable
@property (nonatomic, readonly) NSURL *generic; // nilable
@property (nonatomic, readonly) NSURL *openAccess; // nilable
@property (nonatomic, readonly) NSURL *revoke; // nilable
@property (nonatomic, readonly) NSURL *sample; // nilable
@property (nonatomic, readonly) NSURL *report; // nilable

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

// designated initializer
- (instancetype)initWithBorrow:(NSURL *)borrow
                       generic:(NSURL *)generic
                    openAccess:(NSURL *)openAccess
                        revoke:(NSURL *)revoke
                        sample:(NSURL *)sample
                        report:(NSURL *)report;

// designated initializer
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
