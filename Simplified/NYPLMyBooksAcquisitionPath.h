@import Foundation;

// This must be imported due to referencing of the NYPLOPDSAcquisitionRelation
// enum.
#import "NYPLOPDSAcquisition.h"

/// Represents a single path the application can take through an acquisition
/// process.
@interface NYPLMyBooksAcquisitionPath : NSObject

/// The relation of the initial acquisition step.
@property (nonatomic, readonly) NYPLOPDSAcquisitionRelation relation;

/// The types of the path in acquisition order.
@property (nonatomic, readonly, nonnull) NSArray<NSString *> *types;

+ (instancetype _Nonnull)new NS_UNAVAILABLE;
- (instancetype _Nonnull)init NS_UNAVAILABLE;

/// O(1). Guaranteed to be consistent across a single application run.
/// @return All types of acqusitions supported by the application, including
/// intermediate indirect acqusition types.
+ (NSSet<NSString *> *_Nonnull)supportedTypes;

/// O(n).
/// @param types The types by which to limit the search for supported paths.
/// @param acqusitions The OPDS acquisitions to search.
/// @return The set of possible acquisition paths supported by the application
/// limited by the types supplied. The order of acquisitions given in @c
/// acquisitions is preserved.
+ (NSOrderedSet<NYPLMyBooksAcquisitionPath *> *_Nonnull)
supportedAcquisitionPathsForAllowedTypes:(NSSet<NSString *> *_Nonnull)types
allowedRelations:(NYPLOPDSAcquisitionRelationSet)relations
acquisitions:(NYPLOPDSAcquisition *_Nonnull)acquisitions;

- (instancetype _Nonnull)initWithRelation:(NYPLOPDSAcquisitionRelation)relation
                                    types:(NSArray<NSString *> *_Nonnull)types
  NS_DESIGNATED_INITIALIZER;

@end
