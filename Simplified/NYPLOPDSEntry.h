@class NYPLOPDSCategory;
@class NYPLOPDSEntryGroupAttributes;
@class NYPLOPDSEvent;
@class NYPLXML;

@interface NYPLOPDSEntry : NSObject

@property (nonatomic, readonly) NSString *alternativeHeadline; // nilable
@property (nonatomic, readonly) NSArray *authorStrings;
@property (nonatomic, readonly) NSArray<NYPLOPDSCategory *> *categories;
@property (nonatomic, readonly) NYPLOPDSEntryGroupAttributes *groupAttributes; // nilable
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSArray *links;
@property (nonatomic, readonly) NSString *providerName; // nilable
@property (nonatomic, readonly) NSDate *published; // nilable
@property (nonatomic, readonly) NSString *publisher; // nilable
@property (nonatomic, readonly) NSString *summary; // nilable
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSDate *updated;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

// designated initializer
- (instancetype)initWithXML:(NYPLXML *)entryXML;

@end
