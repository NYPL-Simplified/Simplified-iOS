@class NYPLBookAcquisition;
@class NYPLOPDSEntry;
@class NYPLOPDSEvent;

typedef NS_ENUM(NSInteger, NYPLBookAvailabilityStatus) {
  NYPLBookAvailabilityStatusUnknown      = 1 << 0,
  NYPLBookAvailabilityStatusAvailable    = 1 << 1,
  NYPLBookAvailabilityStatusUnavailable  = 1 << 2,
  NYPLBookAvailabilityStatusReady        = 1 << 3,
  NYPLBookAvailabilityStatusReserved     = 1 << 4
};

@interface NYPLBook : NSObject

@property (nonatomic, readonly) NYPLBookAcquisition *acquisition;
@property (nonatomic, readonly) NSString *authors;
@property (nonatomic, readonly) NSArray *authorLinks;
@property (nonatomic, readonly) NSArray *authorStrings;
@property (nonatomic, readonly) NYPLBookAvailabilityStatus availabilityStatus;
@property (nonatomic, readonly) NSInteger availableCopies;
@property (nonatomic, readonly) NSDate *availableUntil;
@property (nonatomic, readonly) NSString *categories;
@property (nonatomic, readonly) NSArray *categoryStrings;
@property (nonatomic, readonly) NSString *distributor; // nilable
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSURL *imageURL; // nilable
@property (nonatomic, readonly) NSURL *imageThumbnailURL; // nilable
@property (nonatomic, readonly) NSDate *published; // nilable
@property (nonatomic, readonly) NSString *publisher; // nilable
@property (nonatomic, readonly) NSString *subtitle; // nilable
@property (nonatomic, readonly) NSString *summary; // nilable
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSDate *updated;
@property (nonatomic, readonly) NSURL *annotationsURL; // nilable
@property (nonatomic, readonly) NSURL *analyticsURL; // nilable
@property (nonatomic, readonly) NSURL *alternateURL; // nilable
@property (nonatomic, readonly) NSURL *relatedWorksURL; // nilable
@property (nonatomic, readonly) NSURL *seriesURL; // nilable
@property (nonatomic, readonly) NSDictionary *licensor; // nilable

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

// Returns nil if the entry is not valid or does not contain a supported format.
+ (instancetype)bookWithEntry:(NYPLOPDSEntry *)entry;

// Return a new book with the acquisition and availability info from this book,
// and metadata from the specified book
- (instancetype)bookWithMetadataFromBook:(NYPLBook *)book;

// designated initializer
- (instancetype)initWithAcquisition:(NYPLBookAcquisition *)acquisition
                        authorLinks:(NSArray *)authorLinks
                      authorStrings:(NSArray *)authorStrings
                 availabilityStatus:(NYPLBookAvailabilityStatus)availabilityStatus
                    availableCopies:(NSInteger)availableCopies
                     availableUntil:(NSDate *)availableUntil
                    categoryStrings:(NSArray *)categoryStrings
                        distributor:(NSString *)distributor
                         identifier:(NSString *)identifier
                           imageURL:(NSURL *)imageURL
                  imageThumbnailURL:(NSURL *)imageThumbnailURL
                          published:(NSDate *)published
                          publisher:(NSString *)publisher
                           subtitle:(NSString *)subtitle
                            summary:(NSString *)summary
                              title:(NSString *)title
                            updated:(NSDate *)updated
                     annotationsURL:(NSURL *)annotationsURL
                       analyticsURL:(NSURL *)analyticsURL
                       alternateURL:(NSURL *)alternateURL
                    relatedWorksURL:(NSURL *)relatedWorksURL
                          seriesURL:(NSURL *)seriesURL
                           licensor:(NSDictionary *)licensor;

// designated initializer
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
