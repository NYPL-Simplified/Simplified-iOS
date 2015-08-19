@class NYPLBookAcquisition;
@class NYPLOPDSEntry;
@class NYPLOPDSEvent;

typedef NS_ENUM(NSInteger, NYPLBookAvailabilityStatus) {
  NYPLBookAvailabilityStatusUnknown      = 1 << 0,
  NYPLBookAvailabilityStatusAvailable    = 1 << 1,
  NYPLBookAvailabilityStatusUnavailable  = 1 << 2,
  NYPLBookAvailabilityStatusReserved     = 1 << 3,
};

@interface NYPLBook : NSObject

@property (nonatomic, readonly) NYPLBookAcquisition *acquisition;
@property (nonatomic, readonly) NSString *authors;
@property (nonatomic, readonly) NSArray *authorStrings;
@property (nonatomic, readonly) NYPLBookAvailabilityStatus availabilityStatus;
@property (nonatomic, readonly) NSInteger availableCopies;
@property (nonatomic, readonly) NSDate *availableUntil;
@property (nonatomic, readonly) NSString *categories;
@property (nonatomic, readonly) NSArray *categoryStrings;
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSURL *imageURL; // nilable
@property (nonatomic, readonly) NSURL *imageThumbnailURL; // nilable
@property (nonatomic, readonly) NSDate *published; // nilable
@property (nonatomic, readonly) NSString *publisher; // nilable
@property (nonatomic, readonly) NSString *subtitle; // nilable
@property (nonatomic, readonly) NSString *summary; // nilable
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSDate *updated;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

+ (instancetype)bookWithEntry:(NYPLOPDSEntry *)entry;

// designated initializer
- (instancetype)initWithAcquisition:(NYPLBookAcquisition *)acquisition
                      authorStrings:(NSArray *)authorStrings
                 availabilityStatus:(NYPLBookAvailabilityStatus)availabilityStatus
                    availableCopies:(NSInteger)availableCopies
                     availableUntil:(NSDate *)availableUntil
                    categoryStrings:(NSArray *)categoryStrings
                         identifier:(NSString *)identifier
                           imageURL:(NSURL *)imageURL
                  imageThumbnailURL:(NSURL *)imageThumbnailURL
                          published:(NSDate *)published
                          publisher:(NSString *)publisher
                           subtitle:(NSString *)subtitle
                            summary:(NSString *)summary
                              title:(NSString *)title
                            updated:(NSDate *)updated;

// designated initializer
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
