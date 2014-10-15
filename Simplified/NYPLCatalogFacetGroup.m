#import "NYPLCatalogFacet.h"

#import "NYPLCatalogFacetGroup.h"

@interface NYPLCatalogFacetGroup ()

@property (nonatomic) NSArray *facets;
@property (nonatomic) NSString *name;

@end

@implementation NYPLCatalogFacetGroup

- (instancetype)initWithFacets:(NSArray *const)facets
                          name:(NSString *const)name
{
  self = [super init];
  if(!self) return nil;
  
  if(!facets) {
    @throw NSInvalidArgumentException;
  }
  
  for(id object in facets) {
    if(![object isKindOfClass:[NYPLCatalogFacet class]]) {
      @throw NSInvalidArgumentException;
    }
  }
  
  self.facets = facets;
  
  if(!name) {
    @throw NSInvalidArgumentException;
  }
  
  self.name = name;
  
  return self;
}

@end
