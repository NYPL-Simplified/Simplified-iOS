@import Foundation;

@class NYPLXML;

@interface NYPLOPDSIndirectAcquisition : NSObject

/// The type of the content indirectly obtainable.
@property (readonly, nonnull) NSString *type;

/// Zero or more nested indirect acquisitions.
@property (readonly, nonnull) NSArray<NYPLOPDSIndirectAcquisition *> *indirectAcquisitions;

- (_Nullable instancetype)init NS_UNAVAILABLE;

+ (instancetype _Nonnull)
indirectAcquisitionWithType:(NSString *_Nonnull)type
indirectAcquisitions:(NSArray<NYPLOPDSIndirectAcquisition *> *_Nonnull)indirectAcquisitions;

+ (instancetype _Nullable)indirectAcquisitionWithXML:(NYPLXML *_Nonnull)xml;

- (instancetype _Nonnull)initWithType:(NSString *_Nonnull)type
                 indirectAcquisitions:(NSArray<NYPLOPDSIndirectAcquisition *> *_Nonnull)indirectAcquisitions
  NS_DESIGNATED_INITIALIZER;

@end
