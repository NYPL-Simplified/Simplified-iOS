#import "NYPLBook.h"
#import "NYPLBookDetailView.h"
#import "NYPLBookRegistry.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLReaderViewController.h"
#import "NYPLRootTabBarController.h"

#import "NYPLBookDetailViewController.h"

@interface NYPLBookDetailViewController () <NYPLBookDetailViewDelegate>

@property (nonatomic) NYPLBook *book;
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
  
  self.book = book;
  
  NYPLBookDetailView *const view = [[NYPLBookDetailView alloc] initWithBook:book];
  view.state = [[NYPLBookRegistry sharedRegistry] stateForIdentifier:book.identifier];
  view.detailViewDelegate = self;
  
  self.view = view;
  
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    self.modalPresentationStyle = UIModalPresentationFormSheet;
  }
  
  self.title = NSLocalizedString(@"BookDetailViewControllerTitle", nil);
  
  self.observers = [NSMutableArray array];
  
  [self.observers addObject:
   [[NSNotificationCenter defaultCenter]
    addObserverForName:NYPLBookRegistryDidChangeNotification
    object:nil
    queue:[NSOperationQueue mainQueue]
    usingBlock:^(__attribute__((unused)) NSNotification *note) {
      NYPLBook *newBook = [[NYPLBookRegistry sharedRegistry] bookForIdentifier:book.identifier];
      if(newBook) {
        self.book = newBook;
        view.book = newBook;
      }
      view.state = [[NYPLBookRegistry sharedRegistry] stateForIdentifier:book.identifier];
    }]];
  
  [self.observers addObject:
   [[NSNotificationCenter defaultCenter]
    addObserverForName:NYPLMyBooksDownloadCenterDidChangeNotification
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
-(void)didSelectCloseButton:(__attribute__((unused)) NYPLBookDetailView *)detailView {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didSelectCancelDownloadFailedForBookDetailView:
(__attribute__((unused)) NYPLBookDetailView *)detailView
{
  [[NYPLMyBooksDownloadCenter sharedDownloadCenter]
   cancelDownloadForBookIdentifier:self.book.identifier];
}
  
- (void)didSelectCancelDownloadingForBookDetailView:
(__attribute__((unused)) NYPLBookDetailView *)detailView
{
  [[NYPLMyBooksDownloadCenter sharedDownloadCenter]
   cancelDownloadForBookIdentifier:self.book.identifier];
}

- (void)didSelectReturnForBookDetailView:(NYPLBookDetailView *const)detailView
{
  [[NYPLMyBooksDownloadCenter sharedDownloadCenter] returnBookWithIdentifier:detailView.book.identifier];
}

- (void)didSelectDownloadForBookDetailView:(__attribute__((unused)) NYPLBookDetailView *)detailView
{
  [[NYPLMyBooksDownloadCenter sharedDownloadCenter] startDownloadForBook:self.book];
}

- (void)didSelectReadForBookDetailView:(__attribute__((unused)) NYPLBookDetailView *)detailView
{
  [[NYPLRootTabBarController sharedController]
   pushViewController:[[NYPLReaderViewController alloc]
                       initWithBookIdentifier:self.book.identifier]
   animated:YES];
}

- (void)didSelectTryAgainForBookDetailView:(__attribute__((unused)) NYPLBookDetailView *)detailView
{
  [[NYPLMyBooksDownloadCenter sharedDownloadCenter] startDownloadForBook:self.book];
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
