@class RDNavigationElement;

@interface NYPLReaderTOCElement : NSObject

@property (nonatomic, readonly) RDNavigationElement *navigationElement;
@property (nonatomic, readonly) NSUInteger nestingLevel;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;

- (instancetype)initWithNavigationElement:(RDNavigationElement *)navigationElement
                             nestingLevel:(NSUInteger)nestingLevel;

@end
