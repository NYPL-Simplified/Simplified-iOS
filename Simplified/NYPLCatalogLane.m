#import "NYPLBook.h"

#import "NYPLCatalogLane.h"

@interface NYPLCatalogLane ()

@property (nonatomic) NSArray *books;
@property (nonatomic) NSURL *subsectionURL;
@property (nonatomic) NSString *title;

@end

@implementation NYPLCatalogLane

- (instancetype)initWithBooks:(NSArray *const)books
                subsectionURL:(NSURL *const)subsectionURL
                        title:(NSString *const)title
{
  self = [super init];
  if(!self) return nil;
  
  if(!(books && title)) {
    @throw NSInvalidArgumentException;
  }
  
  for(id object in books) {
    if(![object isKindOfClass:[NYPLBook class]]) {
      @throw NSInvalidArgumentException;
    }

    NYPLBook *const book = object;

    if(!book.defaultAcquisition) {
      // The application is not able to support this, so we ignore it.
      continue;
    }
  }
  
  self.books = books;
  self.subsectionURL = subsectionURL;
  self.title = title;
  
  return self;
}

@end
