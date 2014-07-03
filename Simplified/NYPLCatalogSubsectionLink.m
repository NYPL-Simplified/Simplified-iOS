#import "NYPLCatalogSubsectionLink.h"

@interface NYPLCatalogSubsectionLink ()

@property (nonatomic) NYPLCatalogSubsectionLinkType type;
@property (nonatomic) NSURL *URL;

@end

@implementation NYPLCatalogSubsectionLink

- (instancetype)initWithType:(NYPLCatalogSubsectionLinkType const)type URL:(NSURL *const)URL
{
  self = [super init];
  if(!self) return nil;
  
  if(!URL) {
    @throw NSInvalidArgumentException;
  }
  
  self.type = type;
  self.URL = URL;
  
  return self;
}

@end
