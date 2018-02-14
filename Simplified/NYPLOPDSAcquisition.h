@import Foundation;

@protocol NYPLOPDSAcquisitionAvailability;

@class NYPLOPDSIndirectAcquisition;
@class NYPLXML;

/// One of the six acquisition relations given in the OPDS specification.
typedef NS_ENUM(NSInteger, NYPLOPDSAcquisitionRelation) {
  NYPLOPDSAcquisitionRelationGeneric,
  NYPLOPDSAcquisitionRelationOpenAccess,
  NYPLOPDSAcquisitionRelationBorrow,
  NYPLOPDSAcquisitionRelationBuy,
  NYPLOPDSAcquisitionRelationSample,
  NYPLOPDSAcquisitionRelationSubscribe
};

/// Represents zero or more relations given in the OPDS specification.
typedef NS_OPTIONS(NSUInteger, NYPLOPDSAcquisitionRelationSet) {
  NYPLOPDSAcquisitionRelationSetGeneric    = 1 << 0,
  NYPLOPDSAcquisitionRelationSetOpenAccess = 1 << 1,
  NYPLOPDSAcquisitionRelationSetBorrow     = 1 << 2,
  NYPLOPDSAcquisitionRelationSetBuy        = 1 << 3,
  NYPLOPDSAcquisitionRelationSetSample     = 1 << 4,
  NYPLOPDSAcquisitionRelationSetSubscribe  = 1 << 5
};

/// A set containing all possible relations.
extern NYPLOPDSAcquisitionRelationSet const NYPLOPDSAcquisitionRelationSetAll;

/// @param relation The relation with which to form a single-element set.
/// @return A relation set containing a single relation.
NYPLOPDSAcquisitionRelationSet
NYPLOPDSAcquisitionRelationSetWithRelation(NYPLOPDSAcquisitionRelation relation);

/// @return @c YES if @c relation is in @c relationSet, else @c NO.
BOOL
NYPLOPDSAcquisitionRelationSetContainsRelation(NYPLOPDSAcquisitionRelationSet relationSet,
                                               NYPLOPDSAcquisitionRelation relation);

/// @param string A string representing one of the six OPDS acqusition
/// relations.
/// @param relationPointer A pointer to an @c NYPLOPDSAcquisitionRelation that
/// will have been set to a valid relation if and only if the function returns
/// @c YES.
/// @return @c YES if the string was parsed successfully, else @c NO. In the
/// event that @c NO is returned, @c *relationPointer is undefined.
BOOL
NYPLOPDSAcquisitionRelationWithString(NSString *_Nonnull string,
                                      NYPLOPDSAcquisitionRelation *_Nonnull relationPointer);

/// @param The @c NYPLOPDSAcquisitionRelation to convert to a string.
/// @return The associated string.
NSString *_Nonnull
NYPLOPDSAcquisitionRelationString(NYPLOPDSAcquisitionRelation relation);

/// An OPDS acqusition link, i.e. a @c link XML element within an OPDS entry
/// that contains an acquisition @c rel attribute.
@interface NYPLOPDSAcquisition : NSObject

/// The relation of the acqusition link.
@property (nonatomic, readonly) NYPLOPDSAcquisitionRelation relation;

/// The type of content immediately retreivable at the location specified by the
/// @c href property.
@property (nonatomic, readonly, nonnull) NSString *type;

/// The location at which content of type @c type can be retreived.
@property (nonatomic, readonly, nonnull) NSURL *hrefURL;

/// Zero or more indirect acquisition objects.
@property (nonatomic, readonly, nonnull) NSArray<NYPLOPDSIndirectAcquisition *> *indirectAcquisitions;

/// The availability of the result of the acquisition.
@property (nonatomic, readonly, nonnull) id<NYPLOPDSAcquisitionAvailability> availability;

+ (instancetype _Null_unspecified)new NS_UNAVAILABLE;
- (instancetype _Null_unspecified)init NS_UNAVAILABLE;

+ (instancetype _Nonnull)acquisitionWithRelation:(NYPLOPDSAcquisitionRelation)relation
                                            type:(NSString *_Nonnull)type
                                         hrefURL:(NSURL *_Nonnull)hrefURL
                            indirectAcquisitions:(NSArray<NYPLOPDSIndirectAcquisition *> *_Nonnull)indirectAcqusitions
                                    availability:(id<NYPLOPDSAcquisitionAvailability> _Nonnull)availability;

+ (instancetype _Nullable)acquisitionWithLinkXML:(NYPLXML *_Nonnull)linkXML;

- (instancetype _Nonnull)initWithRelation:(NYPLOPDSAcquisitionRelation)relation
                                     type:(NSString *_Nonnull)type
                                  hrefURL:(NSURL *_Nonnull)hrefURL
                     indirectAcquisitions:(NSArray<NYPLOPDSIndirectAcquisition *> *_Nonnull)indirectAcqusitions
                             availability:(id<NYPLOPDSAcquisitionAvailability> _Nonnull)availability
  NS_DESIGNATED_INITIALIZER;

/// @param dictionary An @c NSDictionary created via the @c dictionary method.
/// @return An acqusition if the dictionary was valid.
+ (instancetype _Nullable)acquisitionWithDictionary:(NSDictionary *_Nonnull)dictionary;

/// @return A serialized form of an acqusition suitable for passing to the
/// @c acquisitionWithDictionary: method for later deserialization.
- (NSDictionary *_Nonnull)dictionaryRepresentation;

@end
