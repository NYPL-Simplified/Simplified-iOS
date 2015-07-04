@class NYPLXML;
@class NYPLOPDSEntryGroupAttributes;

@interface NYPLOPDSEntry : NSObject

@property (nonatomic, readonly) NSString *alternativeHeadline; // nilable
@property (nonatomic, readonly) NSArray *authorStrings;
@property (nonatomic, readonly) NSArray *categoryStrings;
@property (nonatomic, readonly) NYPLOPDSEntryGroupAttributes *groupAttributes; // nilable
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSArray *links;
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
