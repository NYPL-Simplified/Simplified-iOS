@import Foundation;

@class NYPLXML;

typedef NSUInteger NYPLOPDSAcquisitionAvailabilityCopies;

extern NYPLOPDSAcquisitionAvailabilityCopies const NYPLOPDSAcquisitionAvailabilityCopiesUnknown;

@class NYPLOPDSAcquisitionAvailabilityUnavailable;
@class NYPLOPDSAcquisitionAvailabilityLimited;
@class NYPLOPDSAcquisitionAvailabilityUnlimited;

@protocol NYPLOPDSAcquisitionAvailability

@property (nonatomic, readonly) BOOL available;

- (void)matchUnavailable:(void (^ _Nullable)(NYPLOPDSAcquisitionAvailabilityUnavailable *_Nonnull))unavailable
                 limited:(void (^ _Nullable)(NYPLOPDSAcquisitionAvailabilityLimited *_Nonnull))limited
               unlimited:(void (^ _Nullable)(NYPLOPDSAcquisitionAvailabilityUnlimited *_Nonnull))unlimited;

+ (instancetype _Null_unspecified)new NS_UNAVAILABLE;
- (instancetype _Null_unspecified)init NS_UNAVAILABLE;

@end

/// @param linkXML XML from an OPDS entry where @c linkXML.name == @c @"link".
/// @return A value of one of the three availability information types.
id<NYPLOPDSAcquisitionAvailability> _Nonnull
NYPLOPDSAcquisitionAvailabilityWithLinkXML(NYPLXML *_Nonnull linkXML);

@interface NYPLOPDSAcquisitionAvailabilityUnavailable : NSObject <NYPLOPDSAcquisitionAvailability>

@property (nonatomic, readonly) NYPLOPDSAcquisitionAvailabilityCopies copiesHeld;
@property (nonatomic, readonly) NYPLOPDSAcquisitionAvailabilityCopies copiesTotal;

@end

@interface NYPLOPDSAcquisitionAvailabilityLimited : NSObject <NYPLOPDSAcquisitionAvailability>

@property (nonatomic, readonly) NYPLOPDSAcquisitionAvailabilityCopies copiesAvailable;
@property (nonatomic, readonly) NYPLOPDSAcquisitionAvailabilityCopies copiesTotal;

@end

@interface NYPLOPDSAcquisitionAvailabilityUnlimited : NSObject <NYPLOPDSAcquisitionAvailability>

@end
