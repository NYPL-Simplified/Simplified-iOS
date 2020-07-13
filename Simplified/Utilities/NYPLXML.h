/**
 Wrapper around NSXMLParser.

 @note This class does not do any logging to Crashlytics.

 @note This class does not intelligently support mixed-content elements: All children are always
NYPLXML objects representing elements, and all text nodes within the parent are concatenated into a
single value. This is simple and convenient for parsing most data formats (e.g. OPDS), but it is not
suitable for handling markup (e.g. XHTML).
 */
@interface NYPLXML : NSObject

@property (nonatomic, readonly) NSDictionary *attributes;
@property (nonatomic, readonly) NSArray *children;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *namespaceURI;
@property (nonatomic, weak, readonly) NYPLXML *parent; // nilable
@property (nonatomic, readonly) NSString *qualifiedName;
@property (nonatomic, readonly) NSString *value;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (instancetype)XMLWithData:(NSData *)data;

- (NSArray *)childrenWithName:(NSString *)name;

- (NYPLXML *)firstChildWithName:(NSString *)name;

@end
