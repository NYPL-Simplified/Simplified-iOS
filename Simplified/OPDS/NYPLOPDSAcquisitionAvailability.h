@import Foundation;

@class NYPLXML;

typedef NSUInteger NYPLOPDSAcquisitionAvailabilityCopies;

extern NYPLOPDSAcquisitionAvailabilityCopies const NYPLOPDSAcquisitionAvailabilityCopiesUnknown;

@class NYPLOPDSAcquisitionAvailabilityUnavailable;
@class NYPLOPDSAcquisitionAvailabilityLimited;
@class NYPLOPDSAcquisitionAvailabilityUnlimited;
@class NYPLOPDSAcquisitionAvailabilityReserved;
@class NYPLOPDSAcquisitionAvailabilityReady;

@protocol NYPLOPDSAcquisitionAvailability

/// When this availability state began.
/// See https://git.io/JmCQT for full semantics.
@property (nonatomic, readonly, nullable) NSDate *since;

/// When this availability state will end.
/// See https://git.io/JmCQT for full semantics.
@property (nonatomic, readonly, nullable) NSDate *until;

- (void)
matchUnavailable:(void (^ _Nullable)(NYPLOPDSAcquisitionAvailabilityUnavailable *_Nonnull unavailable))unavailable
limited:(void (^ _Nullable)(NYPLOPDSAcquisitionAvailabilityLimited *_Nonnull limited))limited
unlimited:(void (^ _Nullable)(NYPLOPDSAcquisitionAvailabilityUnlimited *_Nonnull unlimited))unlimited
reserved:(void (^ _Nullable)(NYPLOPDSAcquisitionAvailabilityReserved *_Nonnull reserved))reserved
ready:(void (^ _Nullable)(NYPLOPDSAcquisitionAvailabilityReady *_Nonnull ready))ready;

@end

/// @param linkXML XML from an OPDS entry where @c linkXML.name == @c @"link".
/// @return A value of one of the three availability information types. If the
/// input is not valid, @c NYPLOPDSAcquisitionAvailabilityUnlimited is returned.
id<NYPLOPDSAcquisitionAvailability> _Nonnull
NYPLOPDSAcquisitionAvailabilityWithLinkXML(NYPLXML *_Nonnull linkXML);

/// @param dictionary Serialized availability information created with
/// @c NYPLOPDSAcquisitionAvailabilityDictionaryRepresentation.
/// @return Availability information or @c nil if the input is not sensible.
id<NYPLOPDSAcquisitionAvailability> _Nullable
NYPLOPDSAcquisitionAvailabilityWithDictionary(NSDictionary *_Nonnull dictionary);

/// @param availability The availability information to serialize.
/// @return The serialized result for use with
/// @c NYPLOPDSAcquisitionAvailabilityWithDictionary.
NSDictionary *_Nonnull
NYPLOPDSAcquisitionAvailabilityDictionaryRepresentation(id<NYPLOPDSAcquisitionAvailability> _Nonnull availability);

@interface NYPLOPDSAcquisitionAvailabilityUnavailable : NSObject <NYPLOPDSAcquisitionAvailability>

@property (nonatomic, readonly) NYPLOPDSAcquisitionAvailabilityCopies copiesHeld;
@property (nonatomic, readonly) NYPLOPDSAcquisitionAvailabilityCopies copiesTotal;

+ (instancetype _Null_unspecified)new NS_UNAVAILABLE;
- (instancetype _Null_unspecified)init NS_UNAVAILABLE;

- (instancetype _Nonnull)initWithCopiesHeld:(NYPLOPDSAcquisitionAvailabilityCopies)copiesHeld
                                copiesTotal:(NYPLOPDSAcquisitionAvailabilityCopies)copiesTotal
  NS_DESIGNATED_INITIALIZER;

@end

@interface NYPLOPDSAcquisitionAvailabilityLimited : NSObject <NYPLOPDSAcquisitionAvailability>

@property (nonatomic, readonly) NYPLOPDSAcquisitionAvailabilityCopies copiesAvailable;
@property (nonatomic, readonly) NYPLOPDSAcquisitionAvailabilityCopies copiesTotal;

+ (instancetype _Null_unspecified)new NS_UNAVAILABLE;
- (instancetype _Null_unspecified)init NS_UNAVAILABLE;

- (instancetype _Nonnull)initWithCopiesAvailable:(NYPLOPDSAcquisitionAvailabilityCopies)copiesAvailable
                                     copiesTotal:(NYPLOPDSAcquisitionAvailabilityCopies)copiesTotal
                                           since:(NSDate *_Nullable)since
                                           until:(NSDate *_Nullable)until
  NS_DESIGNATED_INITIALIZER;

@end

@interface NYPLOPDSAcquisitionAvailabilityUnlimited : NSObject <NYPLOPDSAcquisitionAvailability>

@end

@interface NYPLOPDSAcquisitionAvailabilityReserved : NSObject <NYPLOPDSAcquisitionAvailability>

/// If equal to @c 1, the user is next in line. This value is never @c 0.
@property (nonatomic, readonly) NSUInteger holdPosition;
@property (nonatomic, readonly) NYPLOPDSAcquisitionAvailabilityCopies copiesTotal;

+ (instancetype _Null_unspecified)new NS_UNAVAILABLE;
- (instancetype _Null_unspecified)init NS_UNAVAILABLE;

- (instancetype _Nonnull)initWithHoldPosition:(NSUInteger)holdPosition
                                  copiesTotal:(NYPLOPDSAcquisitionAvailabilityCopies)copiesTotal
                                        since:(NSDate *_Nullable)since
                                        until:(NSDate *_Nullable)until
  NS_DESIGNATED_INITIALIZER;

@end

@interface NYPLOPDSAcquisitionAvailabilityReady : NSObject <NYPLOPDSAcquisitionAvailability>

+ (instancetype _Null_unspecified)new NS_UNAVAILABLE;
- (instancetype _Null_unspecified)init NS_UNAVAILABLE;

- (instancetype _Nonnull)initWithSince:(NSDate *_Nullable)since
                                 until:(NSDate *_Nullable)until
  NS_DESIGNATED_INITIALIZER;

@end
