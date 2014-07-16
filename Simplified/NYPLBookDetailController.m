#import "NYPLBookDetailViewControllerPhone.h"
#import "NYPLBookDetailViewPad.h"
#import "NYPLMyBooksDownloadCenter.h"

#import "NYPLBookDetailController.h"

@interface NYPLBookDetailController () <NYPLBookDetailViewDelegate, NYPLBookDetailViewPadDelegate>

@end

@implementation NYPLBookDetailController

+ (instancetype)sharedController
{
  static dispatch_once_t predicate;
  static NYPLBookDetailController *sharedBookDetailController;
  
  dispatch_once(&predicate, ^{
    sharedBookDetailController = [[self alloc] init];
    if(!sharedBookDetailController) {
      NYPLLOG(@"Failed to created shared book detail controller.");
    }
  });
  
  return sharedBookDetailController;
}

- (void)displayBook:(NYPLBook *const)book fromViewController:(UIViewController *const)controller
{
  switch(UI_USER_INTERFACE_IDIOM()) {
    case UIUserInterfaceIdiomPhone:
      [controller.navigationController
       pushViewController:[[NYPLBookDetailViewControllerPhone alloc] initWithBook:book]
       animated:YES];
      break;
    case UIUserInterfaceIdiomPad:
      {
        NYPLBookDetailViewPad *const view = [[NYPLBookDetailViewPad alloc] initWithBook:book];
        view.delegate = self;
        [view animateDisplayInView:controller.view];
      }
      break;
  }
}

#pragma mark NYPLBookDetailViewDelegate

- (void)didSelectDownloadForDetailView:(NYPLBookDetailView *const)detailView
{
  [[NYPLMyBooksDownloadCenter sharedDownloadCenter] startDownloadForBook:detailView.book];
}

#pragma mark NYPLBookDetailViewPadDelegate

- (void)didSelectCloseForBookDetailViewPad:(NYPLBookDetailViewPad *const)bookDetailViewPad
{
  [bookDetailViewPad animateRemoveFromSuperview];
}

@end
