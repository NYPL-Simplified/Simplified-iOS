@class NYPLXML;

typedef NS_ENUM(NSInteger, NYPLOPDSFeedType) {
  NYPLOPDSFeedTypeInvalid,
  NYPLOPDSFeedTypeAcquisitionGrouped,
  NYPLOPDSFeedTypeAcquisitionUngrouped,
  NYPLOPDSFeedTypeNavigation
};

@interface NYPLOPDSFeed : NSObject

@property (nonatomic, readonly) NSArray *entries;
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSArray *links;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NYPLOPDSFeedType type;
@property (nonatomic, readonly) NSDate *updated;
@property (nonatomic, readonly) NSDictionary *licensor;
@property (nonatomic, readonly) NSString *authorizationIdentifier;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

/// Designated initializer.
- (instancetype)initWithXML:(NYPLXML *)feedXML;

@end
