#import "NYPLCatalogBook.h"

#import "NYPLCatalogLane.h"

@interface NYPLCatalogLane ()

@property (nonatomic) NSArray *books;
@property (nonatomic) NSString *title;

@end

@implementation NYPLCatalogLane

- (id)initWithBooks:(NSArray *const)books
              title:(NSString *const)title
{
  self = [super init];
  if(!self) return nil;
  
  if(!(books && title)) {
    @throw NSInvalidArgumentException;
  }
  
  for(id object in books) {
    if(![object isKindOfClass:[NYPLCatalogBook class]]) {
      @throw NSInvalidArgumentException;
    }
  }
  
  self.books = books;
  self.title = title;
  
  return self;
}

@end
