#import "NYPLCatalogSubsectionLink.h"

@interface NYPLCatalogSubsectionLink ()

@property (nonatomic) NYPLCatalogSubsectionLinkType type;
@property (nonatomic) NSURL *url;

@end

@implementation NYPLCatalogSubsectionLink

- (id)initWithType:(NYPLCatalogSubsectionLinkType const)type url:(NSURL *const)url
{
  self = [super init];
  if(!self) return nil;
  
  if(!url) {
    @throw NSInvalidArgumentException;
  }
  
  self.type = type;
  self.url = url;
  
  return self;
}

@end
