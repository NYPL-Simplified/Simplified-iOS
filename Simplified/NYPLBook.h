@class NYPLBookAcquisition;
@class NYPLOPDSEntry;

@interface NYPLBook : NSObject

@property (nonatomic, readonly) NYPLBookAcquisition *acquisition;
@property (nonatomic, readonly) NSString *authors;
@property (nonatomic, readonly) NSArray *authorStrings;
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

// designated initializer for Preloaded Content
- (instancetype)initPreloadedWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
