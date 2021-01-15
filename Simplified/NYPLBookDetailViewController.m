#import "NYPLBook.h"
#import "NYPLBookDetailView.h"
#import "NYPLBookRegistry.h"
#import "NYPLCatalogFeedViewController.h"
#import "NYPLCatalogLane.h"
#import "NYPLCatalogLaneCell.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLMyBooksDownloadInfo.h"
#import "NYPLRootTabBarController.h"
#import "NYPLSession.h"
#import "NYPLProblemReportViewController.h"
#import "NSURLRequest+NYPLURLRequestAdditions.h"
#import "SimplyE-Swift.h"
#import <PureLayout/PureLayout.h>

#import "NYPLBookDetailViewController.h"

@interface NYPLBookDetailViewController () <NYPLBookDetailViewDelegate, NYPLProblemReportViewControllerDelegate, NYPLCatalogLaneCellDelegate, UIAdaptivePresentationControllerDelegate>

@property (nonatomic) NYPLBook *book;
@property (nonatomic) NYPLBookDetailView *bookDetailView;

-(void)didCacheProblemDocument;

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
  
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad &&
     [[NYPLRootTabBarController sharedController] traitCollection].horizontalSizeClass != UIUserInterfaceSizeClassCompact) {
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
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didCacheProblemDocument)
                                               name:NSNotification.NYPLProblemDocumentWasCached
                                             object:nil];
  
  return self;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  if(self.presentingViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular &&
     self.navigationController.viewControllers.count <= 1) {
    self.navigationController.navigationBarHidden = YES;
  } else {
    self.navigationController.navigationBarHidden = NO;
  }
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  if (self.bookDetailView.summaryTextView.frame.size.height < SummaryTextAbbreviatedHeight) {
    self.bookDetailView.readMoreLabel.hidden = YES;
  } else {
    self.bookDetailView.readMoreLabel.alpha = 0.0;
    self.bookDetailView.readMoreLabel.hidden = NO;
    [UIView animateWithDuration:0.3 animations:^{
      self.bookDetailView.readMoreLabel.alpha = 1.0;
    } completion:^(__unused BOOL finished) {
      self.bookDetailView.readMoreLabel.alpha = 1.0;
    }];
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
  BOOL isIPad = self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular;
  problemVC.modalPresentationStyle = isIPad ? UIModalPresentationPopover : UIModalPresentationOverCurrentContext;
  problemVC.popoverPresentationController.sourceView = sender;
  problemVC.popoverPresentationController.sourceRect = ((UIView *)sender).bounds;
  problemVC.book = book;
  problemVC.delegate = self;
  UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:problemVC];
  if(self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
  }
  [self.navigationController pushViewController:problemVC animated:YES];
}

- (void)didSelectMoreBooksForLane:(NYPLCatalogLane *)lane
{
  NSURL *urlToLoad = lane.subsectionURL;
  if (urlToLoad == nil) {
    NSString *msg = [NSString stringWithFormat:@"Lane %@ has no subsection URL to display more books",
                     lane.title];
    [NYPLErrorLogger logErrorWithCode:NYPLErrorCodeNoURL
                              summary:NSStringFromClass([self class])
                              message:msg
                             metadata:@{
                               @"methodName": @"didSelectMoreBooksForLane:"
                             }];
  }

  UIViewController *const viewController = [[NYPLCatalogFeedViewController alloc]
                                            initWithURL:urlToLoad];
  viewController.title = lane.title;
  [self.navigationController pushViewController:viewController animated:YES];
}

- (void)problemReportViewController:(NYPLProblemReportViewController *)problemReportViewController didSelectProblemWithType:(NSString *)type
{
  NSURL *reportURL = problemReportViewController.book.reportURL;
  if (reportURL) {
    NSURLRequest *r = [NSURLRequest postRequestWithProblemDocument:@{@"type":type} url:reportURL];
    [[NYPLSession sharedSession] uploadWithRequest:r completionHandler:nil];
  }
  if (problemReportViewController.navigationController) {
    [problemReportViewController.navigationController popViewControllerAnimated:YES];
  } else {
    [problemReportViewController dismissViewControllerAnimated:YES completion:nil];
  }
}

#pragma mark -

- (void)didChangePreferredContentSize
{
  [self.bookDetailView updateFonts];
}

- (void)presentFromViewController:(UIViewController *)viewController{
  NSUInteger index = [[NYPLRootTabBarController sharedController] selectedIndex];

  UIViewController *currentVCTab = [[[NYPLRootTabBarController sharedController] viewControllers] objectAtIndex:index];
  // If a VC is already presented as a form sheet (iPad), we push the next one
  // so the user can navigate through multiple book details without "stacking" them.
  if((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ||
      viewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) ||
     currentVCTab.presentedViewController != nil)
  {
    [viewController.navigationController pushViewController:self animated:YES];
  } else {
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:self];
    navVC.modalPresentationStyle = UIModalPresentationFormSheet;
    [viewController presentViewController:navVC animated:YES completion:nil];
  }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
  if (previousTraitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact &&
      self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
    [self.navigationController popToRootViewControllerAnimated:NO];
  }
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)__unused controller
                                                               traitCollection:(UITraitCollection *)traitCollection
{
  if (traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
    return UIModalPresentationFormSheet;
  } else {
    return UIModalPresentationNone;
  }
}

-(void)didCacheProblemDocument {
  if (![NSThread isMainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.bookDetailView.tableViewDelegate configureViewIssuesCell];
      [self.bookDetailView.footerTableView reloadData];
      [self.bookDetailView.footerTableView invalidateIntrinsicContentSize];
    });
  } else {
    [self.bookDetailView.tableViewDelegate configureViewIssuesCell];
    [self.bookDetailView.footerTableView reloadData];
    [self.bookDetailView.footerTableView invalidateIntrinsicContentSize];
  }
}

- (void)didSelectViewIssuesForBook:(NYPLBook *)book sender:(id)__unused sender {
  NYPLProblemDocument* pDoc = [[NYPLProblemDocumentCacheManager sharedInstance] getLastCachedDoc:book.identifier];
  if (pDoc) {
    NYPLBookDetailsProblemDocumentViewController* vc = [[NYPLBookDetailsProblemDocumentViewController alloc] initWithProblemDocument:pDoc book:book];
    UINavigationController* navVC = [self navigationController];
    if (navVC) {
      [navVC pushViewController:vc animated:YES];
    }
  }
}

@end
