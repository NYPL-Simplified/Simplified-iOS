#import "NYPLBookDetailViewControllerPhone.h"
#import "NYPLBookDetailViewPad.h"

#import "NYPLBookDetailController.h"

@interface NYPLBookDetailController ()

@property (nonatomic) NYPLBook *book;

@end

@implementation NYPLBookDetailController

- (instancetype)initWithBook:(NYPLBook *const)book
{
  self = [super init];
  if(!self) return nil;
  
  self.book = book;
  
  return self;
}

- (void)displayFromViewController:(UIViewController *const)controller
{
  switch(UI_USER_INTERFACE_IDIOM()) {
    case UIUserInterfaceIdiomPhone:
      [controller.navigationController
       pushViewController:[[NYPLBookDetailViewControllerPhone alloc] initWithBook:self.book]
       animated:YES];
      break;
    case UIUserInterfaceIdiomPad:
      [[[NYPLBookDetailViewPad alloc] initWithBook:self.book] animateDisplayInView:controller.view];
      break;
  }
}

@end
