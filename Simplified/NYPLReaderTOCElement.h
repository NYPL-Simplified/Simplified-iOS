@class NYPLReaderRendererOpaqueLocation;

@interface NYPLReaderTOCElement : NSObject

@property (nonatomic, readonly) NSUInteger nestingLevel;
@property (nonatomic, readonly) NYPLReaderRendererOpaqueLocation *opaqueLocation;
@property (nonatomic, readonly) NSString *title;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

- (instancetype)initWithOpaqueLocation:(NYPLReaderRendererOpaqueLocation *)opaqueLocation
                                 title:(NSString *)title
                          nestingLevel:(NSUInteger)nestingLevel;

@end
