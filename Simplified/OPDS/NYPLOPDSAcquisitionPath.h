@import Foundation;

// This must be imported due to referencing of the NYPLOPDSAcquisitionRelation
// enum.
#import "NYPLOPDSAcquisition.h"

/// The constant value is fully lowercased.
extern NSString * const _Nonnull ContentTypeOPDSCatalog;
/// The constant value is fully lowercased.
extern NSString * const _Nonnull ContentTypeAdobeAdept;
/// The constant value is fully lowercased.
extern NSString * const _Nonnull ContentTypeBearerToken;
/// The constant value is fully lowercased.
extern NSString * const _Nonnull ContentTypeEpubZip;
/// The constant value is fully lowercased.
extern NSString * const _Nonnull ContentTypeFindaway;
/// The constant value is fully lowercased.
extern NSString * const _Nonnull ContentTypeOpenAccessAudiobook;
/// The constant value is fully lowercased.
extern NSString * const _Nonnull ContentTypeOpenAccessPDF;
/// The constant value is fully lowercased.
extern NSString * const _Nonnull ContentTypeFeedbooksAudiobook;
/// The constant value is fully lowercased.
extern NSString * const _Nonnull ContentTypeOctetStream;
/// The constant value is fully lowercased.
extern NSString * const _Nonnull ContentTypeOverdriveAudiobook;
/// The actual Content-Type returned from Overdrive in the HTTP response for a
/// download request. The constant value is fully lowercased.
extern NSString * const _Nonnull ContentTypeOverdriveAudiobookActual;
/// The constant value is fully lowercased.
extern NSString * const _Nonnull ContentTypeReadiumLCP;
/// The constant value is fully lowercased.
extern NSString * const _Nonnull ContentTypeAudiobookZip;

/// Represents a single path the application can take through an acquisition
/// process.
@interface NYPLOPDSAcquisitionPath : NSObject

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

/// @return Audiobook types of acqusitions 
+ (NSSet<NSString *> *_Nonnull)audiobookTypes;

/// O(n).
/// @param types The types by which to limit the search for supported paths.
/// Paths will also be limited by supported sub-types.
/// @param acqusitions The OPDS acquisitions to search.
/// @return The array of possible acquisition paths supported by the application, limited
/// by the types and relations supplied, deduplicated, in the order they appear.
+ (NSArray<NYPLOPDSAcquisitionPath *> *_Nonnull)
supportedAcquisitionPathsForAllowedTypes:(NSSet<NSString *> *_Nonnull)types
allowedRelations:(NYPLOPDSAcquisitionRelationSet)relations
acquisitions:(NSArray<NYPLOPDSAcquisition *> *_Nonnull)acquisitions;

/// @param types A non-empty array of strings representing response types.
- (instancetype _Nonnull)initWithRelation:(NYPLOPDSAcquisitionRelation)relation
                                    types:(NSArray<NSString *> *_Nonnull)types
                                      url:(NSURL *_Nonnull)url
  NS_DESIGNATED_INITIALIZER;

@end
