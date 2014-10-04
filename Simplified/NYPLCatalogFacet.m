#import "NYPLCatalogFacet.h"

@interface NYPLCatalogFacet ()

@property (nonatomic) BOOL active;
@property (nonatomic) NSURL *href;
@property (nonatomic) NSString *title;

@end

@implementation NYPLCatalogFacet

- (instancetype)initWithActive:(BOOL const)active
                          href:(NSURL *const)href
                         title:(NSString *const)title
{
  self = [super init];
  if(!self) return nil;
  
  self.active = active;
  
  if(!href) {
    @throw NSInvalidArgumentException;
  }
  
  self.href = href;
  
  if(!title) {
    @throw NSInvalidArgumentException;
  }
  
  self.title = title;
  
  return self;
}

@end
