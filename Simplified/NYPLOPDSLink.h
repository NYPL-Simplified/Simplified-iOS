@class NYPLXML;

@interface NYPLOPDSLink : NSObject

@property (nonatomic, readonly) NSDictionary *attributes;
@property (nonatomic, readonly) NSURL *href;
@property (nonatomic, readonly) NSString *rel; // nilable
@property (nonatomic, readonly) NSString *type; // nilable
@property (nonatomic, readonly) NSString *hreflang; // nilable
@property (nonatomic, readonly) NSString *title; // nilable
@property (nonatomic, readonly) NSString *length; // nilable
@property (nonatomic, readonly) NSString *availabilityStatus; // nilable
@property (nonatomic, readonly) NSInteger availableCopies;
@property (nonatomic, readonly) NSDate *availableSince; // nilable
@property (nonatomic, readonly) NSDate *availableUntil; // nilable

// FIXME: This should not be here: Most links are not acquisition links and the
// representation of indirect acquisitions should be handled elsewhere.
@property (nonatomic, readonly) NSArray *acquisitionFormats;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

// designated initializer
- (instancetype)initWithXML:(NYPLXML *)linkXML;

@end
