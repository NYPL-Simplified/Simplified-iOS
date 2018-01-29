@class NYPLOPDSAcquisition;
@class NYPLOPDSEntry;
@class NYPLOPDSEvent;
@class NYPLBookAuthor;

@interface NYPLBook : NSObject

@property (nonatomic, readonly) NSArray<NYPLOPDSAcquisition *> *acquisitions;
@property (nonatomic, readonly) NSString *authors;
@property (nonatomic, readonly) NSArray<NYPLBookAuthor *> *bookAuthors;
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
@property (nonatomic, readonly) NSURL *revokeURL; // nilable
@property (nonatomic, readonly) NSURL *reportURL; // nilable

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

// Returns nil if the entry is not valid or does not contain a supported format.
+ (instancetype)bookWithEntry:(NYPLOPDSEntry *)entry;

// Return a new book with the acquisition and availability info from this book,
// and metadata from the specified book
- (instancetype)bookWithMetadataFromBook:(NYPLBook *)book;

- (instancetype)initWithAcquisitions:(NSArray<NYPLOPDSAcquisition *> *)acquisitions
                         bookAuthors:(NSArray<NYPLBookAuthor *> *)authors
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
                           revokeURL:(NSURL *)revokeURL
                           reportURL:(NSURL *)reportURL
  NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary NS_DESIGNATED_INITIALIZER;

- (NSDictionary *)dictionaryRepresentation;

/// A compatibility method to allow the app to continue to function until the
/// user interface and other components support handling multiple valid
/// acquisition possibilities. Its use should be avoided wherever possible and
/// it will eventually be removed.
///
/// @return An acquisition leading to an EPUB or @c nil.
- (NYPLOPDSAcquisition *)defaultAcquisition __deprecated;

/// A compatibility method to allow the app to continue to function until the
/// user interface and other components support handling multiple valid
/// acquisition possibilities. Its use should be avoided wherever possible and
/// it will eventually be removed.
///
/// @return The default acquisition leading to an EPUB if it has a borrow
/// relation, else @c nil.
- (NYPLOPDSAcquisition *)defaultAcquisitionIfBorrow __deprecated;

/// A compatibility method to allow the app to continue to function until the
/// user interface and other components support handling multiple valid
/// acquisition possibilities. Its use should be avoided wherever possible and
/// it will eventually be removed.
///
/// @return The default acquisition leading to an EPUB if it has an open access
/// relation, else @c nil.
- (NYPLOPDSAcquisition *)defaultAcquisitionIfOpenAccess __deprecated;

@end
