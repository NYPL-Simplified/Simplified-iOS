#import "NYPLBook.h"
#import "NYPLBookAcquisition.h"
#import "NYPLBookDetailView.h"
#import "NYPLBookRegistry.h"
#import "NYPLCatalogLane.h"
#import "NYPLCatalogLaneCell.h"
#import "NYPLCatalogSearchViewController.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLMyBooksDownloadInfo.h"
#import "NYPLReaderViewController.h"
#import "NYPLRootTabBarController.h"
#import "NYPLSession.h"
#import "NYPLProblemReportViewController.h"
#import "NSURLRequest+NYPLURLRequestAdditions.h"
#import "SimplyE-Swift.h"
#import <PureLayout/PureLayout.h>

#import "NYPLCatalogFeedViewController.h"

#import "NYPLBookDetailViewController.h"

@interface NYPLBookDetailViewController () <NYPLBookDetailViewDelegate, NYPLProblemReportViewControllerDelegate, NYPLCatalogLaneCellDelegate>

@property (nonatomic) NYPLBook *book;
@property (nonatomic) NYPLBookDetailView *bookDetailView;

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
  
  self.title = book.title;
  UILabel *label = [[UILabel alloc] init];
  self.navigationItem.titleView = label;
  
  self.bookDetailView = [[NYPLBookDetailView alloc] initWithBook:book delegate:self];
  self.bookDetailView.state = [[NYPLBookRegistry sharedRegistry] stateForIdentifier:book.identifier];
  
  [self.view addSubview:self.bookDetailView];
  [self.bookDetailView autoPinEdgesToSuperviewEdges];
  
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    self.modalPresentationStyle = UIModalPresentationFormSheet;
  }
  
  [[NSNotificationCenter defaultCenter]
   addObserverForName:NYPLBookRegistryDidChangeNotification
   object:nil
   queue:[NSOperationQueue mainQueue]
   usingBlock:^(__attribute__((unused)) NSNotification *note) {
     NYPLBook *newBook = [[NYPLBookRegistry sharedRegistry] bookForIdentifier:book.identifier];
     if(newBook) {
       self.book = newBook;
       self.bookDetailView.book = newBook;
     }
     self.bookDetailView.state = [[NYPLBookRegistry sharedRegistry] stateForIdentifier:book.identifier];
   }];
  
  [[NSNotificationCenter defaultCenter]
   addObserverForName:NYPLMyBooksDownloadCenterDidChangeNotification
   object:nil
   queue:[NSOperationQueue mainQueue]
   usingBlock:^(__attribute__((unused)) NSNotification *note) {
     self.bookDetailView.downloadProgress = [[NYPLMyBooksDownloadCenter sharedDownloadCenter]
                                             downloadProgressForBookIdentifier:book.identifier];
     self.bookDetailView.downloadStarted = [[NYPLMyBooksDownloadCenter sharedDownloadCenter]
                                            downloadInfoForBookIdentifier:book.identifier].rightsManagement != NYPLMyBooksDownloadRightsManagementUnknown;
   }];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didChangePreferredContentSize)
                                               name:UIContentSizeCategoryDidChangeNotification
                                             object:nil];
  
  return self;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && self.navigationController.viewControllers.count <= 1) {
    self.navigationController.navigationBarHidden = YES;
  } else {
    self.navigationController.navigationBarHidden = NO;
  }
}

#pragma mark NSObject

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (void)didSelectCitationsForBook:(NYPLBook *)book sender:(id)sender
{
  //FIXME: add logic for launching citations here
}

#pragma mark - NYPLCatalogLaneCellDelegate

- (void)catalogLaneCell:(NYPLCatalogLaneCell *)cell
     didSelectBookIndex:(NSUInteger)bookIndex
{
  NYPLCatalogLane *const lane = self.bookDetailView.tableViewDelegate.catalogLanes[cell.laneIndex];
  NYPLBook *const feedBook = lane.books[bookIndex];
  NYPLBook *const localBook = [[NYPLBookRegistry sharedRegistry] bookForIdentifier:feedBook.identifier];
  NYPLBook *const book = (localBook != nil) ? localBook : feedBook;
  [[[NYPLBookDetailViewController alloc] initWithBook:book] presentFromViewController:self];
}

#pragma mark - ProblemReportViewControllerDelegate

-(void)didSelectReportProblemForBook:(NYPLBook *)book sender:(id)sender
{
  NYPLProblemReportViewController *problemVC = [[NYPLProblemReportViewController alloc] initWithNibName:@"NYPLProblemReportViewController" bundle:nil];
  BOOL isIPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
  problemVC.modalPresentationStyle = isIPad ? UIModalPresentationPopover : UIModalPresentationOverCurrentContext;
  problemVC.popoverPresentationController.sourceView = sender;
  problemVC.popoverPresentationController.sourceRect = ((UIView *)sender).bounds;
  problemVC.book = book;
  problemVC.delegate = self;
  UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:problemVC];
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
  }
  [self.navigationController pushViewController:problemVC animated:YES];
}

- (void)didSelectMoreBooksForLane:(NYPLCatalogLane *)lane
{
  UIViewController *const viewController = [[NYPLCatalogFeedViewController alloc]
                                            initWithURL:lane.subsectionURL];
  viewController.title = lane.title;
  [self.navigationController pushViewController:viewController animated:YES];
}

- (void)problemReportViewController:(NYPLProblemReportViewController *)problemReportViewController didSelectProblemWithType:(NSString *)type
{
  NSURL *reportURL = problemReportViewController.book.acquisition.report;
  if (reportURL) {
    NSURLRequest *r = [NSURLRequest postRequestWithProblemDocument:@{@"type":type} url:reportURL];
    [[NYPLSession sharedSession] uploadWithRequest:r completionHandler:nil];
  }
  [problemReportViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -

- (void)didChangePreferredContentSize
{
  [self.bookDetailView updateFonts];
}

- (void)presentFromViewController:(UIViewController *)viewController{
  NSUInteger index = [[NYPLRootTabBarController sharedController] selectedIndex];
  UINavigationItem *navItem = viewController.navigationItem;
  if ([viewController isKindOfClass:[NYPLCatalogSearchViewController class]]) {
    [navItem setBackBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Search", nil) style:UIBarButtonItemStylePlain target:nil action:nil]];
  }
  else if (index == 0) {
    if (viewController.navigationController.viewControllers.count <= 1 &&
        UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
      [navItem setBackBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Catalog", nil) style:UIBarButtonItemStylePlain target:nil action:nil]];
    }
  }
  else if (index == 1) {
    [navItem setBackBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"MyBooksViewControllerTitle", nil) style:UIBarButtonItemStylePlain target:nil action:nil]];
  }
  else if (index == 2) {
    [navItem setBackBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"HoldsViewControllerTitle", nil) style:UIBarButtonItemStylePlain target:nil action:nil]];
  }
  
  UIViewController *currentVCTab = [[[NYPLRootTabBarController sharedController] viewControllers] objectAtIndex:index];
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone || currentVCTab.presentedViewController != nil) {
    [viewController.navigationController pushViewController:self animated:YES];
  } else {
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:self];
    navVC.modalPresentationStyle = UIModalPresentationFormSheet;
    [viewController presentViewController:navVC animated:YES completion:nil];
  }
}

@end
