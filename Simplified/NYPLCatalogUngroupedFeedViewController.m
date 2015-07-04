#import "NYPLBook.h"
#import "NYPLBookDetailViewController.h"
#import "NYPLBookNormalCell.h"
#import "NYPLCatalogUngroupedFeed.h"
#import "NYPLCatalogFacet.h"
#import "NYPLCatalogFacetGroup.h"
#import "NYPLCatalogSearchViewController.h"
#import "NYPLFacetBarView.h"
#import "NYPLFacetView.h"
#import "NYPLOpenSearchDescription.h"
#import "NYPLReloadView.h"
#import "NYPLRemoteViewController.h"
#import "UIView+NYPLViewAdditions.h"

#import "NYPLCatalogUngroupedFeedViewController.h"

@interface NYPLCatalogUngroupedFeedViewController ()
  <NYPLCatalogUngroupedFeedDelegate, NYPLFacetViewDataSource, NYPLFacetViewDelegate,
   UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic) NYPLFacetBarView *facetBarView;
@property (nonatomic) NYPLCatalogUngroupedFeed *feed;
@property (nonatomic, weak) NYPLRemoteViewController *remoteViewController;
@property (nonatomic) NYPLOpenSearchDescription *searchDescription;

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
  
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                            initWithImage:[UIImage imageNamed:@"Search"]
                                            style:UIBarButtonItemStylePlain
                                            target:self
                                            action:@selector(didSelectSearch)];
  self.navigationItem.rightBarButtonItem.enabled = NO;
  
  if(self.feed.openSearchURL) {
    [self fetchOpenSearchDescription];
  }
  
  [self.collectionView reloadData];
  [self.facetBarView.facetView reloadData];
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
    
    UIEdgeInsets const insets = UIEdgeInsetsMake(CGRectGetMaxY(self.facetBarView.frame),
                                                 0,
                                                 parent.bottomLayoutGuide.length,
                                                 0);
    self.collectionView.contentInset = insets;
    self.collectionView.scrollIndicatorInsets = insets;
    [self.collectionView setContentOffset:CGPointMake(0, -CGRectGetMaxY(self.facetBarView.frame))
                                 animated:NO];
  }
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
  
  [self.collectionView insertItemsAtIndexPaths:indexPaths];
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
