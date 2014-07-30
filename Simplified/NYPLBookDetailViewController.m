#import "NYPLBookDetailView.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLMyBooksRegistry.h"

#import "NYPLBookDetailViewController.h"

@interface NYPLBookDetailViewController () <NYPLBookDetailViewDelegate>

@property (nonatomic) NSMutableArray *observers;

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
  view.state = [[NYPLMyBooksRegistry sharedRegistry] stateForIdentifier:book.identifier];
  view.detailViewDelegate = self;
  
  self.view = view;
  
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    self.modalPresentationStyle = UIModalPresentationFormSheet;
  }
  
  self.title = book.title;
  
  self.observers = [NSMutableArray array];
  
  [self.observers addObject:
   [[NSNotificationCenter defaultCenter]
    addObserverForName:NYPLBookRegistryDidChange
    object:nil
    queue:[NSOperationQueue mainQueue]
    usingBlock:^(__attribute__((unused)) NSNotification *note) {
      view.state = [[NYPLMyBooksRegistry sharedRegistry] stateForIdentifier:book.identifier];
    }]];
  
  [self.observers addObject:
   [[NSNotificationCenter defaultCenter]
    addObserverForName:NYPLMyBooksDownloadCenterDidChange
    object:nil
    queue:[NSOperationQueue mainQueue]
    usingBlock:^(__attribute__((unused)) NSNotification *note) {
      view.downloadProgress = [[NYPLMyBooksDownloadCenter sharedDownloadCenter]
                               downloadProgressForBookIdentifier:book.identifier];
    }]];
  
  return self;
}

#pragma mark NSObject

- (void)dealloc
{
  for(id const observer in self.observers) {
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
  }
}

#pragma mark NYPLBookDetailViewDelegate

- (void)didSelectDownloadForDetailView:(__attribute__((unused)) NYPLBookDetailView *)detailView
{
  // TODO
}

#pragma mark -

- (void)presentFromViewController:(UIViewController *)viewController{
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    [viewController.navigationController pushViewController:self animated:YES];
  } else {
    [viewController presentViewController:self animated:YES completion:nil];
  }
}

@end
