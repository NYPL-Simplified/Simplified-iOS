@class RDNavigationElement;

@interface NYPLReaderTOCElement : NSObject

@property (nonatomic, readonly) RDNavigationElement *navigationElement;
@property (nonatomic, readonly) NSUInteger nestingLevel;

- (instancetype)initWithNavigationElement:(RDNavigationElement *)navigationElement
                             nestingLevel:(NSUInteger)nestingLevel;

@end
