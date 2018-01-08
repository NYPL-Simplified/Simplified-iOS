@import Foundation;

@class NYPLOPDSIndirectAcquisition;

/// One of the six acquisition relations given in the OPDS specification.
typedef NS_ENUM(NSInteger, NYPLOPDSAcquisitionRelation) {
  NYPLOPDSAcquisitionRelationGeneric,
  NYPLOPDSAcquisitionRelationOpenAccess,
  NYPLOPDSAcquisitionRelationBorrow,
  NYPLOPDSAcquisitionRelationBuy,
  NYPLOPDSAcquisitionRelationSample,
  NYPLOPDSAcquisitionRelationSubscribe
};

/// @param string A string representing one of the six OPDS acqusition
/// relations.
/// @param success A pointer to a @c BOOL that will be set to @c YES if @c
/// string is a valid relation, else one that will be set to @c NO.
/// @return An @c NYPLOPDSAcquisitionRelation if and only if @c *success has
/// been set to @c YES, else the result is undefined.
NYPLOPDSAcquisitionRelation
NYPLOPDSAcquisitionRelationWithString(NSString *_Nonnull string, BOOL *_Nonnull success);

/// @param The @c NYPLOPDSAcquisitionRelation to convert to a string.
/// @return The associated string.
NSString *_Nonnull
NYPLOPDSAcquisitionRelationString(NYPLOPDSAcquisitionRelation relation);

/// An OPDS acqusition link, i.e. a @c link XML element within an OPDS entry
/// that contains an acquisition @c rel attribute.
@interface NYPLOPDSAcquisition : NSObject

/// The relation of the acqusition link.
@property (readonly) NYPLOPDSAcquisitionRelation relation;

/// The type of content immediately retreivable at the location specified by the
/// @c href property.
@property (readonly, nonnull) NSString *type;

/// The location at which content of type @c type can be retreived.
@property (readonly, nonnull) NSURL *hrefURL;

/// Zero or more indirect acquisition objects.
@property (readonly, nonnull) NSArray<NYPLOPDSIndirectAcquisition *> *indirectAcquisitions;

- (_Nullable instancetype)init NS_UNAVAILABLE;

+ (_Nonnull instancetype)acquisitionWithRelation:(NYPLOPDSAcquisitionRelation)relation
                                            type:(NSString *_Nonnull)type
                                         hrefURL:(NSURL *_Nonnull)hrefURL
                            indirectAcquisitions:(NSArray<NYPLOPDSIndirectAcquisition *> *_Nonnull)indirectAcqusitions;

- (_Nonnull instancetype)initWithRelation:(NYPLOPDSAcquisitionRelation)relation
                                     type:(NSString *_Nonnull)type
                                  hrefURL:(NSURL *_Nonnull)hrefURL
                     indirectAcquisitions:(NSArray<NYPLOPDSIndirectAcquisition *> *_Nonnull)indirectAcqusitions
  NS_DESIGNATED_INITIALIZER;

@end
