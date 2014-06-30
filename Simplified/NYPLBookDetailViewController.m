#import "NYPLBookDetailView.h"

#import "NYPLBookDetailViewController.h"

@implementation NYPLBookDetailViewController

- (instancetype)initWithBook:(NYPLCatalogBook *const)book coverImage:(UIImage *const)coverImage
{
  self = [super initWithNibName:nil bundle:nil];
  if(!self) return nil;
  
  if(!book) {
    @throw NSInvalidArgumentException;
  }
  
  if(UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone) {
    NYPLLOG(@"Being created for unexpected user interface idiom.");
  }
  
  NYPLBookDetailView *const view =
    [[NYPLBookDetailView alloc] initWithBook:book coverImage:coverImage];
  
  self.view = view;
  
  self.title = book.title;
  
  return self;
}

@end
