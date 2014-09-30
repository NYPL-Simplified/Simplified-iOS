#import "NYPLBook.h"
#import "NYPLBookNormalCell.h"
#import "NYPLBookDetailViewController.h"
#import "NYPLCatalogCategory.h"
#import "NYPLCatalogSearchViewController.h"
#import "NYPLConfiguration.h"
#import "NYPLReloadView.h"
#import "UIView+NYPLViewAdditions.h"

#import "NYPLCatalogCategoryViewController.h"

@interface NYPLCatalogCategoryViewController ()
  <NYPLCatalogCategoryDelegate, UICollectionViewDataSource, UICollectionViewDelegate,
   UICollectionViewDelegateFlowLayout>

@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic) NYPLCatalogCategory *category;
@property (nonatomic) NYPLReloadView *reloadView;
@property (nonatomic) NSURL *URL;

@end

@implementation NYPLCatalogCategoryViewController

- (instancetype)initWithURL:(NSURL *const)URL
                      title:(NSString *const)title
{
  self = [super init];
  if(!self) return nil;
  
  self.URL = URL;
  
  self.title = title;
  
  return self;
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.collectionView.dataSource = self;
  self.collectionView.delegate = self;
  
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                            initWithImage:[UIImage imageNamed:@"Search"]
                                            style:UIBarButtonItemStylePlain
                                            target:self
                                            action:@selector(didSelectSearch)];
  
  self.navigationItem.rightBarButtonItem.enabled = NO;
  
  self.activityIndicatorView = [[UIActivityIndicatorView alloc]
                                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  self.activityIndicatorView.hidden = YES;
  [self.view addSubview:self.activityIndicatorView];
  
  __weak NYPLCatalogCategoryViewController *weakSelf = self;
  self.reloadView = [[NYPLReloadView alloc] init];
  self.reloadView.handler = ^{
    weakSelf.reloadView.hidden = YES;
    [weakSelf downloadFeed];
  };
  self.reloadView.hidden = YES;
  [self.view addSubview:self.reloadView];
  
  [self downloadFeed];
}

- (void)viewWillLayoutSubviews
{
  self.activityIndicatorView.center = self.view.center;
  [self.activityIndicatorView integralizeFrame];
  
  [self.reloadView centerInSuperview];
  [self.reloadView integralizeFrame];
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

#pragma mark -

- (void)downloadFeed
{
  self.activityIndicatorView.hidden = NO;
  [self.activityIndicatorView startAnimating];
  self.collectionView.hidden = YES;
  
  [NYPLCatalogCategory
   withURL:self.URL
   handler:^(NYPLCatalogCategory *const category) {
     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
       self.activityIndicatorView.hidden = YES;
       [self.activityIndicatorView stopAnimating];
       
       if(!category) {
         self.reloadView.hidden = NO;
         return;
       }
       
       self.collectionView.hidden = NO;
       
       self.category = category;
       self.category.delegate = self;
       
       if(self.category.searchTemplate) {
         self.navigationItem.rightBarButtonItem.enabled = YES;
       }
       
       [self didLoadCategory];
     }];
   }];
}

- (void)didLoadCategory
{
  [self.collectionView reloadData];
}

- (void)didSelectSearch
{
  [self.navigationController
   pushViewController:[[NYPLCatalogSearchViewController alloc]
                       initWithCategoryTitle:self.title
                       searchTemplate:self.category.searchTemplate]
   animated:YES];
}

@end
