#import "NYPLBook.h"
#import "NYPLBookCell.h"
#import "NYPLBookDetailViewController.h"
#import "NYPLConfiguration.h"
#import "NYPLFacetView.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLMyBooksRegistry.h"
#import "UIView+NYPLViewAdditions.h"

#import "NYPLMyBooksViewController.h"

// order-dependent
typedef NS_ENUM(NSInteger, Group) {
  GroupSortBy,
  GroupShow
};

// order-dependent
typedef NS_ENUM(NSInteger, FacetShow) {
  FacetShowAll,
  FacetShowOnLoan
};

// order-dependent
typedef NS_ENUM(NSInteger, FacetSort) {
  FacetSortAuthor,
  FacetSortTitle
};

@interface NYPLMyBooksViewController ()
  <NYPLBookCellDelegate, NYPLFacetViewDataSource, NYPLFacetViewDelegate, UICollectionViewDataSource,
   UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic) FacetShow activeFacetShow;
@property (nonatomic) FacetSort activeFacetSort;
@property (nonatomic) NSArray *books;
@property (nonatomic) UIView *facetBackgroundView;
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
  
  self.activeFacetShow = FacetShowAll;
  self.activeFacetSort = FacetSortAuthor;
  
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
  
  {
    // FIXME: This height is magic.
    CGRect const frame = CGRectMake(0,
                                    CGRectGetMaxY(self.navigationController.navigationBar.frame),
                                    CGRectGetWidth(self.view.frame),
                                    40);
  
    // This is not really the correct way to use a UIToolbar, but it seems to be the simplest way to
    // get a blur effect that matches that of the navigation bar.
    self.facetBackgroundView = [[UIToolbar alloc] initWithFrame:frame];
    self.facetBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.facetBackgroundView];
  }
  
  {
    // FIXME: The 0.5 here assumes a retina display. We should check the scale via UIScreen.
    CGRect const frame = CGRectMake(0,
                                    CGRectGetMaxY(self.facetBackgroundView.frame),
                                    CGRectGetWidth(self.facetBackgroundView.frame),
                                    0.5);
    
    UIView *borderView = [[UIView alloc] initWithFrame:frame];
    borderView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.9];
    borderView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                   UIViewAutoresizingFlexibleTopMargin);
    [self.view addSubview:borderView];
  }
  
  self.facetView = [[NYPLFacetView alloc] initWithFrame:self.facetBackgroundView.bounds];
  self.facetView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight);
  self.facetView.dataSource = self;
  self.facetView.delegate = self;
  [self.facetBackgroundView addSubview:self.facetView];

  self.collectionView.contentInset = UIEdgeInsetsMake(self.collectionView.contentInset.top + 40,
                                                      self.collectionView.contentInset.left,
                                                      self.collectionView.contentInset.bottom,
                                                      self.collectionView.contentInset.right);
  self.collectionView.scrollIndicatorInsets = self.collectionView.contentInset;
  self.collectionView.dataSource = self;
  self.collectionView.delegate = self;
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
  
  switch(self.activeFacetShow) {
    case FacetShowAll:
      switch(self.activeFacetSort) {
        case FacetSortAuthor:
          self.books = [[[NYPLMyBooksRegistry sharedRegistry] allBooks] sortedArrayUsingComparator:
                        ^NSComparisonResult(NYPLBook *const a, NYPLBook *const b) {
                          return [a.authors compare:b.authors options:NSCaseInsensitiveSearch];
                        }];
          return;
        case FacetSortTitle:
          self.books = [[[NYPLMyBooksRegistry sharedRegistry] allBooks] sortedArrayUsingComparator:
                        ^NSComparisonResult(NYPLBook *const a, NYPLBook *const b) {
                          return [a.title compare:b.title options:NSCaseInsensitiveSearch];
                        }];
          return;
      }
      break;
    case FacetShowOnLoan:
      self.books = @[];
      return;
  }
  
  @throw NSInternalInconsistencyException;
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
nameForFacetGroupAtIndex:(NSUInteger const)index
{
  return @[NSLocalizedString(@"MyBooksViewControllerGroupSortBy", nil),
           NSLocalizedString(@"MyBooksViewControllerGroupShow", nil)
           ][index];
}

- (NSString *)facetView:(__attribute__((unused)) NYPLFacetView *)facetView
nameForFacetAtIndexPath:(NSIndexPath *const)indexPath
{
  switch([indexPath indexAtPosition:0]) {
    case GroupShow:
      switch([indexPath indexAtPosition:1]) {
        case FacetShowAll:
          return NSLocalizedString(@"MyBooksViewControllerFacetAll", nil);
        case FacetShowOnLoan:
          return NSLocalizedString(@"MyBooksViewControllerFacetOnLoan", nil);
      }
      break;
    case GroupSortBy:
      switch([indexPath indexAtPosition:1]) {
        case FacetSortAuthor:
          return NSLocalizedString(@"MyBooksViewControllerFacetAuthor", nil);
        case FacetSortTitle:
          return NSLocalizedString(@"MyBooksViewControllerFacetTitle", nil);
      }
      break;
  }
  
  @throw NSInternalInconsistencyException;
}

- (BOOL)facetView:(__attribute__((unused)) NYPLFacetView *)facetView
isActiveFacetForFacetGroupAtIndex:(__attribute__((unused)) NSUInteger)index
{
  return YES;
}

- (NSUInteger)facetView:(__attribute__((unused)) NYPLFacetView *)facetView
activeFacetIndexForFacetGroupAtIndex:(NSUInteger const)index
{
  switch(index) {
    case GroupShow:
      return self.activeFacetShow;
    case GroupSortBy:
      return self.activeFacetSort;
  }
  
  @throw NSInternalInconsistencyException;
}

#pragma mark NYPLFacetViewDelegate

- (void)facetView:(__attribute__((unused)) NYPLFacetView *)facetView
didSelectFacetAtIndexPath:(NSIndexPath *const)indexPath
{
  switch([indexPath indexAtPosition:0]) {
    case GroupShow:
      switch([indexPath indexAtPosition:1]) {
        case FacetShowAll:
          self.activeFacetShow = FacetShowAll;
          goto OK;
        case FacetShowOnLoan:
          self.activeFacetShow = FacetShowOnLoan;
          goto OK;
      }
      break;
    case GroupSortBy:
      switch([indexPath indexAtPosition:1]) {
        case FacetSortAuthor:
          self.activeFacetSort = FacetSortAuthor;
          goto OK;
        case FacetSortTitle:
          self.activeFacetSort = FacetSortTitle;
          goto OK;
      }
      break;
  }
  
  @throw NSInternalInconsistencyException;
  
OK:
  
  [self.facetView reloadData];
  [self willReloadCollectionViewData];
  [self.collectionView reloadData];
}

@end
