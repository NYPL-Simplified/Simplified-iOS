// TODO: This class duplicates much of the functionality of NYPLCatalogCategoryViewController.
// After it is complete, the common portions must be factored out.

#import "NYPLBookCell.h"
#import "NYPLBookDetailViewController.h"
#import "NYPLCatalogCategory.h"
#import "NYPLConfiguration.h"

#import "NYPLCatalogSearchViewController.h"

@interface NYPLCatalogSearchViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic) NYPLCatalogCategory *category;
@property (nonatomic) NSString *categoryTitle;
@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) NSMutableArray *observers;
@property (nonatomic) UISearchBar *searchBar;
@property (nonatomic) NSString *searchTemplate;

@end

@implementation NYPLCatalogSearchViewController

- (instancetype)initWithCategoryTitle:(NSString *const)categoryTitle
                       searchTemplate:(NSString *const)searchTemplate
{
  self = [super init];
  if(!self) return nil;

  self.categoryTitle = categoryTitle;
  self.observers = [NSMutableArray array];
  self.searchTemplate = searchTemplate;
  
  return self;
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
  
  self.collectionView = [[UICollectionView alloc]
                         initWithFrame:self.view.bounds
                         collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
  NYPLBookCellRegisterClassesForCollectionView(self.collectionView);
  [self.observers addObjectsFromArray:
   NYPLBookCellRegisterNotificationsForCollectionView(self.collectionView)];
  self.collectionView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                          UIViewAutoresizingFlexibleHeight);
  self.collectionView.dataSource = self;
  self.collectionView.delegate = self;
  self.collectionView.backgroundColor = [NYPLConfiguration backgroundColor];
  self.collectionView.hidden = YES;
  [self.view addSubview:self.collectionView];
  
  self.activityIndicatorView = [[UIActivityIndicatorView alloc]
                                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  [self.view addSubview:self.activityIndicatorView];
  
  self.searchBar = [[UISearchBar alloc] init];
  self.searchBar.placeholder =
    [NSString stringWithFormat:NSLocalizedString(@"SearchPlaceholderFormat", nil),
     self.categoryTitle];
  [self.searchBar sizeToFit];
  
  self.navigationItem.titleView = self.searchBar;
}

- (void)viewWillAppear:(__attribute__((unused)) BOOL)animated
{
  [self.searchBar becomeFirstResponder];
}

- (void)viewWillDisappear:(__attribute__((unused)) BOOL)animated
{
  [self.searchBar resignFirstResponder];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
                                duration:(__attribute__((unused)) NSTimeInterval)duration
{
  CGFloat const top = self.collectionView.contentInset.top;
  
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    if(self.interfaceOrientation == UIInterfaceOrientationLandscapeRight ||
       self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
      if(orientation == UIInterfaceOrientationPortrait ||
         orientation == UIInterfaceOrientationPortraitUpsideDown) {
        CGFloat const y = (self.collectionView.contentOffset.y + top) * 1.5 - top;
        self.collectionView.contentOffset = CGPointMake(self.collectionView.contentOffset.x, y);
      }
    } else {
      if(orientation == UIInterfaceOrientationLandscapeRight ||
         orientation == UIInterfaceOrientationLandscapeLeft) {
        CGFloat const y = (self.collectionView.contentOffset.y + top) * (2.0 / 3.0) - top;
        self.collectionView.contentOffset = CGPointMake(self.collectionView.contentOffset.x, y);
      }
    }
  }
  
  [self.collectionView.collectionViewLayout invalidateLayout];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(__attribute__((unused)) UICollectionView *)collectionView
     numberOfItemsInSection:(__attribute__((unused)) NSInteger)section
{
  return self.category.books.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  [self.category prepareForBookIndex:indexPath.row];
  
  NYPLBook *const book = self.category.books[indexPath.row];
  
  return NYPLBookCellDequeue(collectionView, indexPath, book);
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(__attribute__((unused)) UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *const)indexPath
{
  NYPLBook *const book = self.category.books[indexPath.row];
  
  [[[NYPLBookDetailViewController alloc] initWithBook:book] presentFromViewController:self];
}

#pragma mark UICollectionViewDelegateFlowLayout

- (UIEdgeInsets)collectionView:(__attribute__((unused)) UICollectionView *)collectionView
                        layout:(__attribute__((unused)) UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(__attribute__((unused)) NSInteger)section
{
  return UIEdgeInsetsZero;
}

- (CGFloat)collectionView:(__attribute__((unused)) UICollectionView *)collectionView
                   layout:(__attribute__((unused)) UICollectionViewLayout *)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(__attribute__((unused)) NSInteger)section
{
  return 0.0;
}

- (CGFloat)collectionView:(__attribute__((unused)) UICollectionView *)collectionView
                   layout:(__attribute__((unused)) UICollectionViewLayout *)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(__attribute__((unused)) NSInteger)section
{
  return 0.0;
}

- (CGSize)collectionView:(__attribute__((unused)) UICollectionView *)collectionView
                  layout:(__attribute__((unused)) UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(__attribute__((unused)) NSIndexPath *)indexPath
{
  return NYPLBookCellSizeForIdiomAndOrientation(UI_USER_INTERFACE_IDIOM(),
                                                self.interfaceOrientation);
}

#pragma mark NYPLCatalogCategoryDelegate

- (void)catalogCategory:(__attribute__((unused)) NYPLCatalogCategory *)catalogCategory
         didUpdateBooks:(__attribute__((unused)) NSArray *)books
{
  [self.collectionView reloadData];
}

@end
