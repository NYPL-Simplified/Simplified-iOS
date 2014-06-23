#import "NYPLCatalogBook.h"

#import "NYPLCatalogLane.h"

@interface NYPLCatalogLane ()

@property (nonatomic) NSArray *books;
@property (nonatomic) NYPLCatalogSubsectionLink *subsectionLink;
@property (nonatomic) NSString *title;

@end

@implementation NYPLCatalogLane

- (instancetype)initWithBooks:(NSArray *const)books
               subsectionLink:(NYPLCatalogSubsectionLink *const)subsectionLink
                        title:(NSString *const)title
{
  self = [super init];
  if(!self) return nil;
  
  if(!(books && subsectionLink && title)) {
    @throw NSInvalidArgumentException;
  }
  
  for(id object in books) {
    if(![object isKindOfClass:[NYPLCatalogBook class]]) {
      @throw NSInvalidArgumentException;
    }
  }
  
  self.books = books;
  self.subsectionLink = subsectionLink;
  self.title = title;
  
  return self;
}

- (NSSet *)imageURLs
{
  NSMutableSet *const set = [NSMutableSet set];
  
  for(NYPLCatalogBook *const book in self.books) {
    if(book.imageURL) {
      [set addObject:book.imageURL];
    }
  }
  
  return set;
}

@end
