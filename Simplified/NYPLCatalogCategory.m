#import "NYPLAsync.h"
#import "NYPLOPDSFeed.h"

#import "NYPLCatalogCategory.h"

@interface NYPLCatalogCategory ()

@property (nonatomic) NSArray *books;
@property (nonatomic) NSString *title;

@end

@implementation NYPLCatalogCategory

+ (void)withURL:(NSURL *)url handler:(void (^)(NYPLCatalogCategory *category))handler
{
  [NYPLOPDSFeed
   withURL:url
   completionHandler:^(NYPLOPDSFeed *const acquisitionFeed) {
     if(!acquisitionFeed) {
       NYPLLOG(@"Failed to retrieve acquisition feed.");
       NYPLAsyncDispatch(^{handler(nil);});
       return;
     }
     
     // TODO: Load books and title.
     // TODO: Use factored-out book loading from NYPLCatalogRoot.
   }];
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
