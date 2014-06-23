@import Foundation;

typedef enum {
  NYPLCatalogSubsectionLinkTypeAcquisition,
  NYPLCatalogSubsectionLinkTypeNavigation
} NYPLCatalogSubsectionLinkType;

@interface NYPLCatalogSubsectionLink : NSObject

@property (nonatomic, readonly) NYPLCatalogSubsectionLinkType type;
@property (nonatomic, readonly) NSURL *url;

// designated initializer
- (instancetype)initWithType:(NYPLCatalogSubsectionLinkType)type url:(NSURL *)url;

@end
