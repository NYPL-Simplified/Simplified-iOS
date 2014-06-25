#import "NYPLCatalogCategory.h"

#import "NYPLCatalogCategoryViewController.h"

@interface NYPLCatalogCategoryViewController ()

@property (nonatomic) NYPLCatalogCategory *category;

@end

@implementation NYPLCatalogCategoryViewController

- (instancetype)initWithURL:(NSURL *const)url title:(NSString *const)title
{
  self = [super init];
  if(!self) return nil;
  
  self.title = title;
  
  [NYPLCatalogCategory
   withURL:url
   handler:^(NYPLCatalogCategory *const category) {
     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
       self.category = category;
       // TODO: Kick off display of data.
     }];
   }];
  
  return self;
}

@end
