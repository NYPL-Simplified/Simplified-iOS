// TODO: This class duplicates much of the functionality of NYPLCatalogUngroupedFeedViewController.
// After it is complete, the common portions must be factored out.

#import "NSString+NYPLStringAdditions.h"
#import "NYPLBook.h"
#import "NYPLBookCell.h"
#import "NYPLBookDetailViewController.h"
#import "NYPLCatalogUngroupedFeed.h"
#import "NYPLOpenSearchDescription.h"
#import "NYPLReloadView.h"
#import "UIView+NYPLViewAdditions.h"
#import <PureLayout/PureLayout.h>

#import "NYPLCatalogSearchViewController.h"

@interface NYPLCatalogSearchViewController ()
  <NYPLCatalogUngroupedFeedDelegate, UICollectionViewDelegate, UICollectionViewDataSource,
   UISearchBarDelegate>

@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic) UILabel *activityIndicatorLabel;
@property (nonatomic) NYPLCatalogUngroupedFeed *category;
@property (nonatomic) UILabel *noResultsLabel;
@property (nonatomic) NYPLReloadView *reloadView;
@property (nonatomic) UISearchBar *searchBar;
@property (nonatomic) NYPLOpenSearchDescription *searchDescription;
@property (nonatomic) NSArray *books;

@end

@implementation NYPLCatalogSearchViewController

- (instancetype)initWithOpenSearchDescription:(NYPLOpenSearchDescription *)searchDescription
{
  self = [super init];
  if(!self) return nil;

  self.searchDescription = searchDescription;
  
  return self;
}

- (NSArray *)books
{
  return _books ? _books : self.category.books;
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
  
  self.activityIndicatorLabel = [[UILabel alloc] init];
  self.activityIndicatorLabel.font = [UIFont systemFontOfSize:14.0];
  self.activityIndicatorLabel.text = NSLocalizedString(@"ActivitySlowLoadMessage", @"Message explaining that the download is still going");
  self.activityIndicatorLabel.hidden = YES;
  [self.view addSubview:self.activityIndicatorLabel];
  [self.activityIndicatorLabel autoAlignAxis:ALAxisVertical toSameAxisOfView:self.activityIndicatorView];
  [self.activityIndicatorLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.activityIndicatorView withOffset:8.0];
  
  self.searchBar = [[UISearchBar alloc] init];
  self.searchBar.delegate = self;
  self.searchBar.placeholder = self.searchDescription.humanReadableDescription;
  [self.searchBar sizeToFit];
  [self.searchBar becomeFirstResponder];
  
  self.noResultsLabel = [[UILabel alloc] init];
  self.noResultsLabel.text = NSLocalizedString(@"NoResultsFound", nil);
  self.noResultsLabel.font = [UIFont systemFontOfSize:17];
  [self.noResultsLabel sizeToFit];
  self.noResultsLabel.hidden = YES;
  [self.view addSubview:self.noResultsLabel];
  
    __weak NYPLCatalogSearchViewController *weakSelf = self;
  self.reloadView = [[NYPLReloadView alloc] init];
  self.reloadView.handler = ^{
    weakSelf.reloadView.hidden = YES;
    // |weakSelf.searchBar| will always contain the last search because the reload view is hidden as
    // soon as editing begins (and thus cannot be clicked if the search bar text has changed).
    [weakSelf searchBarSearchButtonClicked:weakSelf.searchBar];
  };
  self.reloadView.hidden = YES;
  [self.view addSubview:self.reloadView];
  
  self.navigationItem.titleView = self.searchBar;
}

- (void)viewWillLayoutSubviews
{
  self.activityIndicatorView.center = self.view.center;
  [self.activityIndicatorView integralizeFrame];
  
  self.noResultsLabel.center = self.view.center;
  self.noResultsLabel.frame = CGRectMake(CGRectGetMinX(self.noResultsLabel.frame),
                                         CGRectGetHeight(self.view.frame) * 0.333,
                                         CGRectGetWidth(self.noResultsLabel.frame),
                                         CGRectGetHeight(self.noResultsLabel.frame));
  [self.noResultsLabel integralizeFrame];
  
  [self.reloadView centerInSuperview];
  [self.reloadView integralizeFrame];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  
  [self.searchBar resignFirstResponder];
}

- (void)addActivityIndicatorLabel:(NSTimer*)timer
{
  if (!self.activityIndicatorView.isHidden) {
    [UIView transitionWithView:self.activityIndicatorLabel
                      duration:0.5
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                      self.activityIndicatorLabel.hidden = NO;
                    } completion:nil];
  }
  [timer invalidate];
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
  [self.category prepareForBookIndex:indexPath.row];
  
  NYPLBook *const book = self.books[indexPath.row];
  
  return NYPLBookCellDequeue(collectionView, indexPath, book);
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(__attribute__((unused)) UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *const)indexPath
{
  NYPLBook *const book = self.books[indexPath.row];
  
  [[[NYPLBookDetailViewController alloc] initWithBook:book] presentFromViewController:self];
}

#pragma mark NYPLCatalogUngroupedFeedDelegate

- (void)catalogUngroupedFeed:(__attribute__((unused))
                              NYPLCatalogUngroupedFeed *)catalogUngroupedFeed
              didUpdateBooks:(__attribute__((unused)) NSArray *)books
{
  [self.collectionView reloadData];
}

- (void)catalogUngroupedFeed:(__unused NYPLCatalogUngroupedFeed *)catalogUngroupedFeed
                 didAddBooks:(__unused NSArray *)books
                       range:(__unused NSRange const)range
{
  // FIXME: This is not ideal but we were having double-free issues with
  // `insertItemsAtIndexPaths:`. See issue #144 for more information.
  [self.collectionView reloadData];
}

#pragma mark UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(__attribute__((unused)) UISearchBar *)searchBar
{
  self.collectionView.hidden = YES;
  self.noResultsLabel.hidden = YES;
  self.reloadView.hidden = YES;
  self.activityIndicatorView.hidden = NO;
  [self.activityIndicatorView startAnimating];

  self.activityIndicatorLabel.hidden = YES;
  [NSTimer scheduledTimerWithTimeInterval: 10.0 target: self
                                 selector: @selector(addActivityIndicatorLabel:) userInfo: nil repeats: NO];
  
  self.searchBar.userInteractionEnabled = NO;
  self.searchBar.alpha = 0.5;
  [self.searchBar resignFirstResponder];
  
  if(self.searchDescription.books) {
    self.books = [self.searchDescription.books filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NYPLBook *book, __unused NSDictionary *bindings) {
      BOOL titleMatch = [book.title.lowercaseString containsString:self.searchBar.text.lowercaseString];
      BOOL authorMatch = [book.authors.lowercaseString containsString:self.searchBar.text.lowercaseString];
      return titleMatch || authorMatch;
    }]];
    [self updateUIAfterSearchSuccess:YES];
  } else {
    [NYPLCatalogUngroupedFeed
     withURL:[NSURL URLWithString:
              [self.searchDescription.OPDSURLTemplate
               stringByReplacingOccurrencesOfString:@"{searchTerms}"
               withString:[self.searchBar.text stringByURLEncoding]]]
     handler:^(NYPLCatalogUngroupedFeed *const category) {
       [[NSOperationQueue mainQueue] addOperationWithBlock:^{
         if(category) {
           self.category = category;
           self.category.delegate = self;
         }
         
         [self updateUIAfterSearchSuccess:(category != nil)];
       }];
     }];
  }
}

- (void)updateUIAfterSearchSuccess:(BOOL)success
{
  self.activityIndicatorView.hidden = YES;
  [self.activityIndicatorView stopAnimating];
  self.activityIndicatorLabel.hidden = YES;
  self.searchBar.userInteractionEnabled = YES;
  self.searchBar.alpha = 1.0;
  
  if(success) {
    self.collectionView.hidden = NO;
    
    [self.collectionView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    [self.collectionView reloadData];
    
    if(self.books.count > 0) {
      self.collectionView.hidden = NO;
    } else {
      self.noResultsLabel.hidden = NO;
    }
  } else {
    self.reloadView.hidden = NO;
  }
}

- (BOOL)searchBarShouldBeginEditing:(__attribute__((unused)) UISearchBar *)searchBar
{
  self.reloadView.hidden = YES;
  
  return YES;
}
                                     
@end
