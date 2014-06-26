#import "NYPLAsync.h"
#import "NYPLCatalogBook.h"
#import "NYPLOPDSEntry.h"
#import "NYPLOPDSFeed.h"
#import "NYPLOPDSLink.h"
#import "NYPLOPDSRelation.h"

#import "NYPLCatalogCategory.h"

@interface NYPLCatalogCategory ()

@property (nonatomic) NSArray *books;
@property (nonatomic) NSURL *nextURL;
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
     
     NSMutableArray *const books = [NSMutableArray arrayWithCapacity:acquisitionFeed.entries.count];
     
     for(NYPLOPDSEntry *const entry in acquisitionFeed.entries) {
       NYPLCatalogBook *const book = [NYPLCatalogBook bookWithEntry:entry];
       if(!book) {
         NYPLLOG(@"Failed to create book from entry.");
         continue;
       }
       [books addObject:book];
     }
     
     NSURL *nextURL = nil;
     
     for(NYPLOPDSLink *const link in acquisitionFeed.links) {
       if([link.rel isEqualToString:NYPLOPDSRelationPaginationNext]) {
         nextURL = link.href;
         break;
       }
     }
     
     NYPLCatalogCategory *const category = [[NYPLCatalogCategory alloc]
                                            initWithBooks:books
                                            nextURL:nextURL
                                            title:acquisitionFeed.title];
     
     NYPLAsyncDispatch(^{handler(category);});
   }];
}

- (instancetype)initWithBooks:(NSArray *const)books
                      nextURL:(NSURL *const)nextURL
                        title:(NSString *const)title
{
  self = [super init];
  if(!self) return nil;
  
  if(!(books && title)) {
    @throw NSInvalidArgumentException;
  }
  
  self.books = books;
  self.nextURL = nextURL;
  self.title = title;
  
  return self;
}

@end
