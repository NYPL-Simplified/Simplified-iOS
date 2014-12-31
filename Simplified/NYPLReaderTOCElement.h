@class RDNavigationElement;

// No such actual class exists. This merely to provides a little safety around reader-specific
// TOC-related location information. Any object that wants to do something with an opaque location
// must verify that it is of the correct class and then cast it appropriately.
@class NYPLReaderOpaqueLocation;

@interface NYPLReaderTOCElement : NSObject

@property (nonatomic, readonly) NSUInteger nestingLevel;
@property (nonatomic, readonly) NYPLReaderOpaqueLocation *opaqueLocation;
@property (nonatomic, readonly) NSString *title;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

- (instancetype)initWithOpaqueLocation:(NYPLReaderOpaqueLocation *)opaqueLocation
                                 title:(NSString *)title
                          nestingLevel:(NSUInteger)nestingLevel;

@end
