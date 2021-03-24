@import Foundation;

@class NYPLXML;

@interface NYPLOPDSIndirectAcquisition : NSObject

/// The type of the content indirectly obtainable.
@property (nonatomic, readonly, nonnull) NSString *type;

/// Zero or more nested indirect acquisitions.
@property (nonatomic, readonly, nonnull) NSArray<NYPLOPDSIndirectAcquisition *> *indirectAcquisitions;

+ (instancetype _Null_unspecified)new NS_UNAVAILABLE;
- (instancetype _Null_unspecified)init NS_UNAVAILABLE;

+ (instancetype _Nonnull)
indirectAcquisitionWithType:(NSString *_Nonnull)type
indirectAcquisitions:(NSArray<NYPLOPDSIndirectAcquisition *> *_Nonnull)indirectAcquisitions;

+ (instancetype _Nullable)indirectAcquisitionWithXML:(NYPLXML *_Nonnull)xml;

- (instancetype _Nonnull)initWithType:(NSString *_Nonnull)type
                 indirectAcquisitions:(NSArray<NYPLOPDSIndirectAcquisition *> *_Nonnull)indirectAcquisitions
  NS_DESIGNATED_INITIALIZER;

/// @param dictionary An @c NSDictionary created via the @c dictionary method.
/// @return An indirect acqusition if the dictionary was valid.
+ (instancetype _Nullable)indirectAcquisitionWithDictionary:(NSDictionary *_Nonnull)dictionary;

/// @return A serialized form of an acqusition suitable for passing to the
/// @c indirectAcquisitionWithDictionary: method for later deserialization.
- (NSDictionary *_Nonnull)dictionaryRepresentation;

@end
