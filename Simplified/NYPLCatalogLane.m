#import "NYPLCatalogBook.h"

#import "NYPLCatalogLane.h"

@interface NYPLCatalogLane ()

@property (nonatomic) NSArray *books;
@property (nonatomic) NSURL *subsectionURL;
@property (nonatomic) NSString *title;

@end

@implementation NYPLCatalogLane

- (id)initWithBooks:(NSArray *const)books
      subsectionURL:(NSURL *const)subsectionURL
              title:(NSString *const)title
{
  self = [super init];
  if(!self) return nil;
  
  if(!(books && subsectionURL && title)) {
    @throw NSInvalidArgumentException;
  }
  
  for(id object in books) {
    if(![object isKindOfClass:[NYPLCatalogBook class]]) {
      @throw NSInvalidArgumentException;
    }
  }
  
  self.books = books;
  self.subsectionURL = subsectionURL;
  self.title = title;
  
  return self;
}

@end
