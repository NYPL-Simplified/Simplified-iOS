#import "NYPLBookContentType.h"
@class NYPLOPDSAcquisition;
@class NYPLOPDSEntry;
@class NYPLOPDSEvent;
@class NYPLBookAuthor;

@interface NYPLBook : NSObject

@property (nullable, nonatomic, readonly) NSArray<NYPLOPDSAcquisition *> *acquisitions;
@property (nullable, nonatomic, readonly) NSString *authors;
@property (nullable, nonatomic, readonly) NSArray<NYPLBookAuthor *> *bookAuthors;
@property (nullable, nonatomic, readonly) NSString *categories;
@property (nonnull, nonatomic, readonly) NSArray *categoryStrings;
@property (nullable, nonatomic, readonly) NSString *distributor;
@property (nonnull, nonatomic, readonly) NSString *identifier;
@property (nullable, nonatomic, readonly) NSURL *imageURL;
@property (nullable, nonatomic, readonly) NSURL *imageThumbnailURL;
@property (nullable, nonatomic, readonly) NSDate *published;
@property (nullable, nonatomic, readonly) NSString *publisher;
@property (nullable, nonatomic, readonly) NSString *subtitle;
@property (nullable, nonatomic, readonly) NSString *summary;
@property (nonnull, nonatomic, readonly) NSString *title;
@property (nonnull, nonatomic, readonly) NSDate *updated;
@property (nullable, nonatomic, readonly) NSURL *annotationsURL;
@property (nullable, nonatomic, readonly) NSURL *analyticsURL;
@property (nullable, nonatomic, readonly) NSURL *alternateURL;
@property (nullable, nonatomic, readonly) NSURL *relatedWorksURL;
@property (nullable, nonatomic, readonly) NSURL *seriesURL;
@property (nullable, nonatomic, readonly) NSURL *revokeURL;
@property (nullable, nonatomic, readonly) NSURL *reportURL;

+ (nonnull id)new NS_UNAVAILABLE;
- (nonnull id)init NS_UNAVAILABLE;

/// @brief Factory method to build a NYPLBook object from an OPDS feed entry.
///
/// @param entry An OPDS entry to base the book on.
///
/// @return @p nil if the entry does not contain non-nil values for the
/// @p acquisitions, @p categories, @p identifier, @p title, @p updated
/// properties.
+ (nullable instancetype)bookWithEntry:(nullable NYPLOPDSEntry *)entry;

/// @brief This is the designated initializer.
///
/// @discussion Returns @p nil if either one of the values for the following
/// keys is nil: @p "categories", @p "id", @p "title", @p "updated". In all other cases
/// an non-nil instance is returned.
///
/// @param dictionary A JSON-style key-value pair string dictionary.
- (nullable instancetype)initWithDictionary:(nonnull NSDictionary *)dictionary NS_DESIGNATED_INITIALIZER;

/// @return A new book with the @p identifier, @p acquisitions, @p revokeURL
/// and @p reportURL from this book, and metadata from the specified book.
- (nonnull instancetype)bookWithMetadataFromBook:(nonnull NYPLBook *)book;

- (nonnull NSDictionary *)dictionaryRepresentation;

/// @discussion
/// A compatibility method to allow the app to continue to function until the
/// user interface and other components support handling multiple valid
/// acquisition possibilities. Its use should be avoided wherever possible and
/// it will eventually be removed.
///
/// @seealso @b https://jira.nypl.org/browse/SIMPLY-2588
///
/// @return An acquisition leading to an EPUB or @c nil.
- (nullable NYPLOPDSAcquisition *)defaultAcquisition;

/// @discussion
/// A compatibility method to allow the app to continue to function until the
/// user interface and other components support handling multiple valid
/// acquisition possibilities. Its use should be avoided wherever possible and
/// it will eventually be removed.
///
/// @seealso @b https://jira.nypl.org/browse/SIMPLY-2588
///
/// @return The default acquisition leading to an EPUB if it has a borrow
/// relation, else @c nil.
- (nullable NYPLOPDSAcquisition *)defaultAcquisitionIfBorrow;

/// @discussion
/// A compatibility method to allow the app to continue to function until the
/// user interface and other components support handling multiple valid
/// acquisition possibilities. Its use should be avoided wherever possible and
/// it will eventually be removed.
///
/// @seealso @b https://jira.nypl.org/browse/SIMPLY-2588
///
/// @return The default acquisition leading to an EPUB if it has an open access
/// relation, else @c nil.
- (nullable NYPLOPDSAcquisition *)defaultAcquisitionIfOpenAccess;

/// @discussion
/// Assigns the book content type based on the inner-most type listed
/// in the acquistion path. If multiple acquisition paths exist, default
/// to epub+zip before moving down to other supported types. The UI
/// does not yet support more than one supported type.
///
/// @seealso @b https://jira.nypl.org/browse/SIMPLY-2588
///
/// @return The default NYPLBookContentType
- (NYPLBookContentType)defaultBookContentType;

/// Add a custom expiration date to book if
/// 1. book is distributed by Axis360
/// 2. book does not contain an expiration date
- (void)addCustomExpirateDate:(nonnull NSDate *)date;

@end
