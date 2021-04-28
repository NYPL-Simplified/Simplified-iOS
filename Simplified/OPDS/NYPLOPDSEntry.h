@class NYPLOPDSAcquisition;
@class NYPLOPDSCategory;
@class NYPLOPDSEntryGroupAttributes;
@class NYPLOPDSEvent;
@class NYPLXML;
@class NYPLOPDSLink;

@interface NYPLOPDSEntry : NSObject

@property (nonatomic, readonly) NSArray<NYPLOPDSAcquisition *> *acquisitions;
@property (nonatomic, readonly) NSString *alternativeHeadline; // nilable
@property (nonatomic, readonly) NSArray *authorStrings;
@property (nonatomic, readonly) NSArray<NYPLOPDSLink *> *authorLinks;
@property (nonatomic, readonly) NYPLOPDSLink *seriesLink;
@property (nonatomic, readonly) NSArray<NYPLOPDSCategory *> *categories;
@property (nonatomic, readonly) NYPLOPDSEntryGroupAttributes *groupAttributes; // nilable
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSArray *links;
@property (nonatomic, readonly) NYPLOPDSLink *annotations;
@property (nonatomic, readonly) NYPLOPDSLink *alternate;
@property (nonatomic, readonly) NYPLOPDSLink *relatedWorks;
@property (nonatomic, readonly) NSURL *analytics;
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
