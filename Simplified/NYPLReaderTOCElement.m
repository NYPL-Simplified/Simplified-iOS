#import "NYPLReaderTOCElement.h"

@interface NYPLReaderTOCElement ()

@property (nonatomic) RDNavigationElement *navigationElement;
@property (nonatomic) NSUInteger nestingLevel;

@end

@implementation NYPLReaderTOCElement

- (instancetype)initWithNavigationElement:(RDNavigationElement *)navigationElement
                             nestingLevel:(NSUInteger)nestingLevel
{
  self = [super init];
  if(!self) return nil;
  
  if(!navigationElement) {
    @throw NSInvalidArgumentException;
  }
  
  self.navigationElement = navigationElement;
  self.nestingLevel = nestingLevel;
  
  return self;
}

@end
