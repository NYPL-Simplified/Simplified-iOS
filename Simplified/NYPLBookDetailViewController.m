#import "NYPLBookDetailView.h"

#import "NYPLBookDetailViewController.h"

@interface NYPLBookDetailViewController () <NYPLBookDetailViewDelegate>

@end

@implementation NYPLBookDetailViewController

- (instancetype)initWithBook:(NYPLBook *const)book
{
  self = [super initWithNibName:nil bundle:nil];
  if(!self) return nil;
  
  if(!book) {
    @throw NSInvalidArgumentException;
  }
  
  NYPLBookDetailView *const view = [[NYPLBookDetailView alloc] initWithBook:book];
  view.detailViewDelegate = self;
  
  self.view = view;
  
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    self.modalPresentationStyle = UIModalPresentationFormSheet;
  }
  
  self.title = book.title;
  
  return self;
}

- (void)presentFromViewController:(UIViewController *)viewController{
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    [viewController.navigationController pushViewController:self animated:YES];
  } else {
    [viewController presentViewController:self animated:YES completion:nil];
  }
}

#pragma mark NYPLBookDetailViewDelegate

- (void)didSelectDownloadForDetailView:(__attribute__((unused)) NYPLBookDetailView *)detailView
{
  // TODO
}

@end
