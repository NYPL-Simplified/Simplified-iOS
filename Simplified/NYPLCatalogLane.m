#import "NYPLBook.h"

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
  
  // FIXME: |subsectionLink| will no longer always be present and should be allowed to be nil. The
  // name of this variable/property should be changed as well.
  if(!(books && subsectionLink && title)) {
    @throw NSInvalidArgumentException;
  }
  
  for(id object in books) {
    if(![object isKindOfClass:[NYPLBook class]]) {
      @throw NSInvalidArgumentException;
    }
  }
  
  self.books = books;
  self.subsectionLink = subsectionLink;
  self.title = title;
  
  return self;
}

@end
