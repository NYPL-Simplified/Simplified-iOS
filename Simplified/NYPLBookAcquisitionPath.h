@import Foundation;

// This must be imported due to referencing of the NYPLOPDSAcquisitionRelation
// enum.
#import "NYPLOPDSAcquisition.h"

static NSString * const _Nonnull ContentTypeOPDSCatalog = @"application/atom+xml;type=entry;profile=opds-catalog";
static NSString * const _Nonnull ContentTypeAdobeAdept = @"application/vnd.adobe.adept+xml";
static NSString * const _Nonnull ContentTypeBearerToken = @"application/vnd.librarysimplified.bearer-token+json";
static NSString * const _Nonnull ContentTypeEpubZip = @"application/epub+zip";
static NSString * const _Nonnull ContentTypeFindaway = @"application/vnd.librarysimplified.findaway.license+json";
static NSString * const _Nonnull ContentTypeOpenAccessAudiobook = @"application/audiobook+json";

/// Represents a single path the application can take through an acquisition
/// process.
@interface NYPLBookAcquisitionPath : NSObject

/// The relation of the initial acquisition step.
@property (nonatomic, readonly) NYPLOPDSAcquisitionRelation relation;

/// The types of the path in acquisition order. It is guaranteed that
/// @c types.count is at least 1.
@property (nonatomic, readonly, nonnull) NSArray<NSString *> *types;

/// The URL to fetch to begin processing the acquisition path. The server
/// should, but is not guaranteed, to return a response of type @c types[0].
@property (nonatomic, readonly, nonnull) NSURL *url;

+ (instancetype _Null_unspecified)new NS_UNAVAILABLE;
- (instancetype _Null_unspecified)init NS_UNAVAILABLE;

/// O(1). Guaranteed to be consistent across a single application run.
/// @return All types of acqusitions supported by the application, including
/// intermediate indirect acqusition types.
+ (NSSet<NSString *> *_Nonnull)supportedTypes;

/// O(n).
/// @param types The types by which to limit the search for supported paths.
/// @param acqusitions The OPDS acquisitions to search.
/// @return The set of possible acquisition paths supported by the application
/// limited by the types and relations supplied.
+ (NSSet<NYPLBookAcquisitionPath *> *_Nonnull)
supportedAcquisitionPathsForAllowedTypes:(NSSet<NSString *> *_Nonnull)types
allowedRelations:(NYPLOPDSAcquisitionRelationSet)relations
acquisitions:(NSArray<NYPLOPDSAcquisition *> *_Nonnull)acquisitions;

/// @param types A non-empty array of strings representing response types.
- (instancetype _Nonnull)initWithRelation:(NYPLOPDSAcquisitionRelation)relation
                                    types:(NSArray<NSString *> *_Nonnull)types
                                      url:(NSURL *_Nonnull)url
  NS_DESIGNATED_INITIALIZER;

@end
