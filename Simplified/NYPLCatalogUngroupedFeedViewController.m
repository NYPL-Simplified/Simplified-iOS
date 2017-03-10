#import "NYPLBook.h"
#import "NYPLBookDetailViewController.h"
#import "NYPLBookNormalCell.h"
#import "NYPLCatalogUngroupedFeed.h"
#import "NYPLCatalogFacet.h"
#import "NYPLCatalogFacetGroup.h"
#import "NYPLCatalogFeedViewController.h"
#import "NYPLCatalogSearchViewController.h"
#import "NYPLConfiguration.h"
#import "NYPLFacetBarView.h"
#import "NYPLFacetView.h"
#import "NYPLOpenSearchDescription.h"
#import "NYPLReloadView.h"
#import "NYPLRemoteViewController.h"
#import "UIView+NYPLViewAdditions.h"
#import "NYPLSettings.h"

#import "NYPLCatalogUngroupedFeedViewController.h"

static const CGFloat kActivityIndicatorPadding = 20.0;

@interface NYPLCatalogUngroupedFeedViewController ()
  <NYPLCatalogUngroupedFeedDelegate, NYPLFacetViewDataSource, NYPLFacetViewDelegate,
   UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic) NYPLFacetBarView *facetBarView;
@property (nonatomic) NYPLCatalogUngroupedFeed *feed;
@property (nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic, weak) NYPLRemoteViewController *remoteViewController;
@property (nonatomic) NYPLOpenSearchDescription *searchDescription;
@property (nonatomic) UIActivityIndicatorView *activityIndicator;

@end

@implementation NYPLCatalogUngroupedFeedViewController

- (instancetype)initWithUngroupedFeed:(NYPLCatalogUngroupedFeed *const)feed
                 remoteViewController:(NYPLRemoteViewController *const)remoteViewController
{
  self = [super init];
  if(!self) return nil;
  
  self.feed = feed;
  self.feed.delegate = self;
  self.remoteViewController = remoteViewController;
  
  return self;
}

- (UIEdgeInsets)scrollIndicatorInsets
{
  return UIEdgeInsetsMake(CGRectGetMaxY(self.facetBarView.frame),
                          0,
                          self.parentViewController.bottomLayoutGuide.length,
                          0);
}

- (void)updateActivityIndicator
{
  UIEdgeInsets insets = [self scrollIndicatorInsets];
  if(self.feed.currentlyFetchingNextURL) {
    insets.bottom += kActivityIndicatorPadding + self.activityIndicator.frame.size.height;
    CGRect frame = self.activityIndicator.frame;
    frame.origin = CGPointMake(CGRectGetMidX(self.collectionView.frame) - frame.size.width/2,
                               self.collectionView.contentSize.height + kActivityIndicatorPadding/2);
    self.activityIndicator.frame = frame;
  }
  self.activityIndicator.hidden = !self.feed.currentlyFetchingNextURL;
  self.collectionView.contentInset = insets;
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.facetBarView = [[NYPLFacetBarView alloc] initWithOrigin:CGPointZero width:0];
  self.facetBarView.facetView.dataSource = self;
  self.facetBarView.facetView.delegate = self;
  [self.view addSubview:self.facetBarView];
  
  self.collectionView.dataSource = self;
  self.collectionView.delegate = self;
  
  self.collectionView.alwaysBounceVertical = YES;
  self.refreshControl = [[UIRefreshControl alloc] init];
  [self.refreshControl addTarget:self action:@selector(userDidRefresh:) forControlEvents:UIControlEventValueChanged];
  [self.collectionView addSubview:self.refreshControl];
  
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                            initWithImage:[UIImage imageNamed:@"Search"]
                                            style:UIBarButtonItemStylePlain
                                            target:self
                                            action:@selector(didSelectSearch)];
  self.navigationItem.rightBarButtonItem.accessibilityLabel = NSLocalizedString(@"Search", nil);
  self.navigationItem.rightBarButtonItem.enabled = NO;
  
  if(self.feed.openSearchURL) {
    [self fetchOpenSearchDescription];
  }
  
  [self.collectionView reloadData];
  [self.facetBarView.facetView reloadData];
  
  self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  self.activityIndicator.hidden = YES;
  [self.activityIndicator startAnimating];
  [self.collectionView addSubview:self.activityIndicator];
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
  [super didMoveToParentViewController:parent];
  
  if(parent) {
    self.facetBarView.frame =
      CGRectMake(0,
                 CGRectGetMaxY(self.navigationController.navigationBar.frame),
                 CGRectGetWidth(self.view.frame),
                 CGRectGetHeight(self.facetBarView.frame));
    
    [self updateActivityIndicator];
    self.collectionView.scrollIndicatorInsets = [self scrollIndicatorInsets];
    [self.collectionView setContentOffset:CGPointMake(0, -CGRectGetMaxY(self.facetBarView.frame))
                                 animated:NO];
  }
}

- (void)userDidRefresh:(UIRefreshControl *)refreshControl
{
  if ([[self.navigationController.visibleViewController class] isSubclassOfClass:[NYPLCatalogFeedViewController class]] &&
      [self.navigationController.visibleViewController respondsToSelector:@selector(load)]) {
    [self.remoteViewController load];
  }
  
  [refreshControl endRefreshing];
  [[NSNotificationCenter defaultCenter] postNotificationName:NYPLSyncEndedNotification object:nil];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(__attribute__((unused)) UICollectionView *)collectionView
     numberOfItemsInSection:(__attribute__((unused)) NSInteger)section
{
  return self.feed.books.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  [self.feed prepareForBookIndex:indexPath.row];
  [self updateActivityIndicator];
  
  NYPLBook *const book = self.feed.books[indexPath.row];
  
  return NYPLBookCellDequeue(collectionView, indexPath, book);
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(__attribute__((unused)) UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *const)indexPath
{
  NYPLBook *const book = self.feed.books[indexPath.row];
  
  [[[NYPLBookDetailViewController alloc] initWithBook:book] presentFromViewController:self];
}

#pragma mark NYPLCatalogUngroupedFeedDelegate

- (void)catalogUngroupedFeed:(__attribute__((unused))
                              NYPLCatalogUngroupedFeed *)catalogUngroupedFeed
              didUpdateBooks:(__attribute__((unused)) NSArray *)books
{
  [self.collectionView reloadData];
}

- (void)catalogUngroupedFeed:(__attribute__((unused))
                              NYPLCatalogUngroupedFeed *)catalogUngroupedFeed
                 didAddBooks:(__attribute__((unused)) NSArray *)books
                       range:(NSRange const)range
{
  NSMutableArray *const indexPaths = [NSMutableArray arrayWithCapacity:range.length];
  
  for(NSUInteger i = 0; i < range.length; ++i) {
    NSUInteger indexes[2] = {0, i + range.location};
    [indexPaths addObject:[NSIndexPath indexPathWithIndexes:indexes length:2]];
  }
  
  // Just reloadData instead of inserting items, to avoid a weird crash (issue #144).
//  [self.collectionView insertItemsAtIndexPaths:indexPaths];
  [self.collectionView reloadData];
}

#pragma mark NYPLFacetViewDataSource

- (NSUInteger)numberOfFacetGroupsInFacetView:(__attribute__((unused)) NYPLFacetView *)facetView
{
  return self.feed.facetGroups.count;
}

- (NSUInteger)facetView:(__attribute__((unused)) NYPLFacetView *)facetView
numberOfFacetsInFacetGroupAtIndex:(NSUInteger const)index
{
  return ((NYPLCatalogFacetGroup *) self.feed.facetGroups[index]).facets.count;
}

- (NSString *)facetView:(__attribute__((unused)) NYPLFacetView *)facetView
nameForFacetGroupAtIndex:(NSUInteger const)index
{
  return ((NYPLCatalogFacetGroup *) self.feed.facetGroups[index]).name;
}

- (NSString *)facetView:(__attribute__((unused)) NYPLFacetView *)facetView
nameForFacetAtIndexPath:(NSIndexPath *const)indexPath
{
  NYPLCatalogFacetGroup *const group = self.feed.facetGroups[[indexPath indexAtPosition:0]];
  
  NYPLCatalogFacet *const facet = group.facets[[indexPath indexAtPosition:1]];
  
  return facet.title;
}

- (BOOL)facetView:(__attribute__((unused)) NYPLFacetView *)facetView
isActiveFacetForFacetGroupAtIndex:(NSUInteger const)index
{
  NYPLCatalogFacetGroup *const group = self.feed.facetGroups[index];
  
  for(NYPLCatalogFacet *const facet in group.facets) {
    if(facet.active) return YES;
  }
  
  return NO;
}

- (NSUInteger)facetView:(__attribute__((unused)) NYPLFacetView *)facetView
activeFacetIndexForFacetGroupAtIndex:(NSUInteger)index
{
  NYPLCatalogFacetGroup *const group = self.feed.facetGroups[index];
  
  NSUInteger i = 0;
  
  for(NYPLCatalogFacet *const facet in group.facets) {
    if(facet.active) return i;
    ++i;
  }
  
  @throw NSInternalInconsistencyException;
}

#pragma mark NYPLFacetViewDelegate

- (void)facetView:(__attribute__((unused)) NYPLFacetView *)facetView
didSelectFacetAtIndexPath:(NSIndexPath *const)indexPath
{
  NYPLCatalogFacetGroup *const group = self.feed.facetGroups[[indexPath indexAtPosition:0]];
  
  NYPLCatalogFacet *const facet = group.facets[[indexPath indexAtPosition:1]];
  
  self.remoteViewController.URL = facet.href;
  
  [self.remoteViewController load];
}

#pragma mark -

- (void)didSelectSearch
{
  [self.navigationController
   pushViewController:[[NYPLCatalogSearchViewController alloc]
                       initWithOpenSearchDescription:self.searchDescription]
   animated:YES];
}

- (void)fetchOpenSearchDescription
{
  [NYPLOpenSearchDescription
   withURL:self.feed.openSearchURL
   completionHandler:^(NYPLOpenSearchDescription *const description) {
     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
       self.searchDescription = description;
       self.navigationItem.rightBarButtonItem.enabled = YES;
     }];
   }];
}

@end
