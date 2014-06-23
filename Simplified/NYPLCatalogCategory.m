#import "NYPLAsync.h"

#import "NYPLCatalogCategory.h"

@interface NYPLCatalogCategory ()

@property (nonatomic) NSArray *books;
@property (nonatomic) NSString *title;

@end

@implementation NYPLCatalogCategory

+ (void)withURL:(NSURL *)url handler:(void (^)(NYPLCatalogCategory *category))handler
{
  NYPLAsyncFetch(url, ^(__attribute__((unused)) NSData *const data) {
     // TODO
     handler(nil);
  });
}

- (instancetype)initWithBooks:(NSArray *const)books title:(NSString *const)title
{
  self = [super init];
  if(!self) return nil;
  
  if(!(books && title)) {
    @throw NSInvalidArgumentException;
  }
  
  self.books = books;
  self.title = title;
  
  return self;
}

@end
