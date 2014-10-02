#import "NYPLBook.h"
#import "NYPLBookCell.h"
#import "NYPLBookDetailViewController.h"
#import "NYPLConfiguration.h"
#import "NYPLFacetView.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLMyBooksRegistry.h"
#import "UIView+NYPLViewAdditions.h"

#import "NYPLMyBooksViewController.h"

@interface NYPLMyBooksViewController ()
  <NYPLBookCellDelegate, NYPLFacetViewDataSource, NYPLFacetViewDelegate, UICollectionViewDataSource,
   UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic) NSArray *books;
@property (nonatomic) NYPLFacetView *facetView;

@end

@implementation NYPLMyBooksViewController

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;

  self.title = NSLocalizedString(@"MyBooksViewControllerTitle", nil);
  
  [self willReloadCollectionViewData];
  
  return self;
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  CGFloat const navBarBottom = CGRectGetMaxY(self.navigationController.navigationBar.frame);
  
  UIView *const facetBackgroundView = [[UIView alloc]
                                       initWithFrame:CGRectMake(0,
                                                                navBarBottom,
                                                                CGRectGetWidth(self.view.frame),
                                                                40)];
  facetBackgroundView.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.2];
  facetBackgroundView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                          UIViewAutoresizingFlexibleBottomMargin);
  [self.view addSubview:facetBackgroundView];
  
  self.facetView = [[NYPLFacetView alloc] init];
  self.facetView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight);
  self.facetView.dataSource = self;
  self.facetView.delegate = self;
  [facetBackgroundView addSubview:self.facetView];
  
  self.collectionView.dataSource = self;
  self.collectionView.delegate = self;
}

- (void)viewDidLayoutSubviews
{
  [self.facetView sizeToFit];
  [self.facetView centerInSuperview];
  [self.facetView integralizeFrame];
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(__attribute__((unused)) UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *const)indexPath
{
  NYPLBook *const book = self.books[indexPath.row];
  
  [[[NYPLBookDetailViewController alloc] initWithBook:book] presentFromViewController:self];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(__attribute__((unused)) UICollectionView *)collectionView
     numberOfItemsInSection:(__attribute__((unused)) NSInteger)section
{
  return self.books.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  NYPLBook *const book = self.books[indexPath.row];
  
  return NYPLBookCellDequeue(collectionView, indexPath, book);
}

#pragma mark NYPLBookCellCollectionViewController

- (void)willReloadCollectionViewData
{
  [super willReloadCollectionViewData];
  
  self.books = [[[NYPLMyBooksRegistry sharedRegistry] allBooks] sortedArrayUsingComparator:
                ^NSComparisonResult(NYPLBook *const a, NYPLBook *const b) {
                  return [a.title compare:b.title options:NSCaseInsensitiveSearch];
                }];
}

#pragma mark NYPLFacetViewDataSource

- (NSUInteger)numberOfFacetGroupsInFacetView:(__attribute__((unused)) NYPLFacetView *)facetView
{
  return 2;
}

- (NSUInteger)facetView:(__attribute__((unused)) NYPLFacetView *)facetView
numberOfFacetsInFacetGroupAtIndex:(__attribute__((unused)) NSUInteger)index
{
  return 2;
}

- (NSString *)facetView:(__attribute__((unused)) NYPLFacetView *)facetView
nameForFacetGroupAtIndex:(NSUInteger)index
{
  switch(index) {
    case 0:
      return @"Sort by";
    case 1:
      return @"Show";
  }
  
  @throw NSInternalInconsistencyException;
}

- (NSString *)facetView:(__attribute__((unused)) NYPLFacetView *)facetView
nameForFacetAtIndexPath:(NSIndexPath *)indexPath
{
  switch([indexPath indexAtPosition:0]) {
    case 0:
      switch([indexPath indexAtPosition:1]) {
        case 0:
          return @"Author";
        case 1:
          return @"Title";
      }
    case 1:
      switch([indexPath indexAtPosition:1]) {
        case 0:
          return @"All";
        case 1:
          return @"Available";
      }
  }
  
  @throw NSInternalInconsistencyException;
}

- (BOOL)facetView:(__attribute__((unused)) NYPLFacetView *)facetView
isActiveFacetForFacetGroupAtIndex:(__attribute__((unused)) NSUInteger)index
{
  return YES;
}

- (NSUInteger)facetView:(__attribute__((unused)) NYPLFacetView *)facetView
activeFacetIndexForFacetGroupAtIndex:(__attribute__((unused)) NSUInteger)index
{
  return 0;
}

#pragma mark NYPLFacetViewDelegate

- (void)facetView:(__attribute__((unused)) NYPLFacetView *)facetView
didSelectFacetAtIndexPath:(__attribute__((unused)) NSIndexPath *)indexPath
{
  
}

@end
