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
  
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
  
  CGFloat const navBarBottom = CGRectGetMaxY(self.navigationController.navigationBar.frame);
  
  // FIXME: Height of 46 is magic.
  
  // This is not really the correct way to use a UIToolbar, but it seems to be the simplest way to
  // get a blur effect that matches that of the navigation bar.
  UIView *const facetBackgroundView = [[UIToolbar alloc]
                                       initWithFrame:CGRectMake(0,
                                                                navBarBottom,
                                                                CGRectGetWidth(self.view.frame),
                                                                46)];
  facetBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  [self.view addSubview:facetBackgroundView];
  
  UIView *const borderBottomView = [[UIView alloc]
                                    initWithFrame:CGRectMake(0,
                                                             CGRectGetMaxY(facetBackgroundView.frame),
                                                             CGRectGetWidth(self.view.frame),
                                                             0.5)];
  borderBottomView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  borderBottomView.backgroundColor = [UIColor lightGrayColor];
  [self.view addSubview:borderBottomView];
  
  self.collectionView.contentInset = UIEdgeInsetsMake(self.collectionView.contentInset.top + 52,
                                                      self.collectionView.contentInset.left,
                                                      self.collectionView.contentInset.bottom,
                                                      self.collectionView.contentInset.right);
                                                      
  self.facetView = [[NYPLFacetView alloc] initWithFrame:facetBackgroundView.bounds];
  self.facetView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight);
  self.facetView.dataSource = self;
  self.facetView.delegate = self;
  [facetBackgroundView addSubview:self.facetView];
  
  self.collectionView.dataSource = self;
  self.collectionView.delegate = self;
}

- (void)viewDidAppear:(__attribute__((unused)) BOOL)animated
{
  [self.facetView flashScrollIndicators];
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
  return 5;
}

- (NSUInteger)facetView:(__attribute__((unused)) NYPLFacetView *)facetView
numberOfFacetsInFacetGroupAtIndex:(__attribute__((unused)) NSUInteger)index
{
  return 3;
}

- (NSString *)facetView:(__attribute__((unused)) NYPLFacetView *)facetView
nameForFacetGroupAtIndex:(NSUInteger)index
{
  return [NSString stringWithFormat:@"Group %lu", (unsigned long)index];
}

- (NSString *)facetView:(__attribute__((unused)) NYPLFacetView *)facetView
nameForFacetAtIndexPath:(NSIndexPath *)indexPath
{
  return [NSString stringWithFormat:@"Facet %lu", (unsigned long)[indexPath indexAtPosition:1]];
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
