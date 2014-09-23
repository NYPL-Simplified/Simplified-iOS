// TODO: This class duplicates much of the functionality of NYPLCatalogCategoryViewController.
// After it is complete, the common portions must be factored out.

#import "NSString+NYPLStringAdditions.h"
#import "NYPLBookCell.h"
#import "NYPLBookDetailViewController.h"
#import "NYPLCatalogCategory.h"
#import "NYPLConfiguration.h"

#import "NYPLCatalogSearchViewController.h"

@interface NYPLCatalogSearchViewController ()
  <NYPLCatalogCategoryDelegate, UICollectionViewDelegate, UICollectionViewDataSource,
   UISearchBarDelegate>

@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic) NYPLCatalogCategory *category;
@property (nonatomic) NSString *categoryTitle;
@property (nonatomic) UILabel *noResultsLabel;
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
  self.searchTemplate = searchTemplate;
  
  return self;
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.collectionView.dataSource = self;
  self.collectionView.delegate = self;
  
  self.activityIndicatorView = [[UIActivityIndicatorView alloc]
                                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  self.activityIndicatorView.hidden = YES;
  [self.view addSubview:self.activityIndicatorView];
  
  self.searchBar = [[UISearchBar alloc] init];
  self.searchBar.delegate = self;
  self.searchBar.placeholder =
    [NSString stringWithFormat:NSLocalizedString(@"SearchPlaceholderFormat", nil),
     self.categoryTitle];
  [self.searchBar sizeToFit];
  [self.searchBar becomeFirstResponder];
  
  self.noResultsLabel = [[UILabel alloc] init];
  self.noResultsLabel.text = NSLocalizedString(@"NoResultsFound", nil);
  self.noResultsLabel.font = [UIFont systemFontOfSize:17];
  [self.noResultsLabel sizeToFit];
  self.noResultsLabel.hidden = YES;
  [self.view addSubview:self.noResultsLabel];
  
  self.navigationItem.titleView = self.searchBar;
}

- (void)viewWillLayoutSubviews
{
  self.activityIndicatorView.center = self.view.center;
  
  self.noResultsLabel.center = self.view.center;
  self.noResultsLabel.frame = CGRectMake(CGRectGetMinX(self.noResultsLabel.frame),
                                         CGRectGetHeight(self.view.frame) * 0.333,
                                         CGRectGetWidth(self.noResultsLabel.frame),
                                         CGRectGetHeight(self.noResultsLabel.frame));
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  
  [self.searchBar resignFirstResponder];
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

#pragma mark NYPLCatalogCategoryDelegate

- (void)catalogCategory:(__attribute__((unused)) NYPLCatalogCategory *)catalogCategory
         didUpdateBooks:(__attribute__((unused)) NSArray *)books
{
  [self.collectionView reloadData];
}

#pragma mark UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(__attribute__((unused)) UISearchBar *)searchBar
{
  self.collectionView.hidden = YES;
  self.noResultsLabel.hidden = YES;
  self.activityIndicatorView.hidden = NO;
  [self.activityIndicatorView startAnimating];
  [self.searchBar resignFirstResponder];
  
  [NYPLCatalogCategory
   withURL:[NSURL URLWithString:
            [self.searchTemplate
             stringByReplacingOccurrencesOfString:@"{searchTerms}"
             withString:[self.searchBar.text stringByURLEncoding]]]
   handler:^(NYPLCatalogCategory *const category) {
     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
       self.collectionView.hidden = NO;
       self.activityIndicatorView.hidden = YES;
       [self.activityIndicatorView stopAnimating];
       
       // FIXME: This uses the wrong localized string for the title.
       if(!category) {
         [[[UIAlertView alloc]
           initWithTitle:
            NSLocalizedString(@"CatalogCategoryViewControllerFeedDownloadFailedTitle", nil)
           message:
            NSLocalizedString(@"CheckConnection", nil)
           delegate:nil
           cancelButtonTitle:nil
           otherButtonTitles:NSLocalizedString(@"OK", nil), nil]
          show];
         return;
       }
       
       self.category = category;
       self.category.delegate = self;
       
       [self.collectionView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
       [self.collectionView reloadData];
       
       if(self.category.books.count > 0) {
         self.collectionView.hidden = NO;
       } else {
         self.noResultsLabel.hidden = NO;
       }
     }];
   }];
}

@end
