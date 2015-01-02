#import "NYPLReaderTOCElement.h"

@interface NYPLReaderTOCElement ()

@property (nonatomic) NSUInteger nestingLevel;
@property (nonatomic) NYPLReaderRendererOpaqueLocation *opaqueLocation;
@property (nonatomic) NSString *title;

@end

@implementation NYPLReaderTOCElement

- (instancetype)initWithOpaqueLocation:(NYPLReaderRendererOpaqueLocation *const)opaqueLocation
                                 title:(NSString *const)title
                          nestingLevel:(NSUInteger const)nestingLevel
{
  self = [super init];
  if(!self) return nil;
  
  if(!opaqueLocation) {
    @throw NSInvalidArgumentException;
  }
  
  self.nestingLevel = nestingLevel;
  self.opaqueLocation = opaqueLocation;
  self.title = title;
  
  return self;
}

@end
