@class NYPLXML;

@interface NYPLOPDSLink : NSObject

@property (nonatomic, readonly) NSDictionary *attributes;
@property (nonatomic, readonly) NSURL *href;
@property (nonatomic, readonly) NSString *rel;
@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) NSString *hreflang;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *length;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

// designated initializer
- (instancetype)initWithXML:(NYPLXML *)linkXML;

@end
