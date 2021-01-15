#import "NYPLBook.h"
#import "NYPLBookCell.h"
#import "NYPLBookDetailViewController.h"
#import "NYPLBookRegistry.h"
#import "NYPLCatalogSearchViewController.h"
#import "NYPLConfiguration.h"
#import "NYPLFacetView.h"
#import "NYPLOpenSearchDescription.h"
#import "NYPLAccountSignInViewController.h"

#import "NSDate+NYPLDateAdditions.h"
#import "NYPLMyBooksDownloadCenter.h"
#import <PureLayout/PureLayout.h>
#import "UIView+NYPLViewAdditions.h"

#import "NYPLMyBooksViewController.h"

#import "SimplyE-Swift.h"

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

@interface NYPLMyBooksContainerView : UIView
@property (nonatomic) NSArray *accessibleElements;
@end

@implementation NYPLMyBooksContainerView

#pragma mark Accessibility

- (BOOL) isAccessibilityElement {
  return NO;
}

- (NSInteger) accessibilityElementCount {
  return self.accessibleElements.count;
}

- (id) accessibilityElementAtIndex:(NSInteger)index {
  return self.accessibleElements[index];
}

- (NSInteger) indexOfAccessibilityElement:(id)element {
  return [self.accessibleElements indexOfObject:element];
}

@end

@interface NYPLMyBooksViewController ()
  <NYPLFacetViewDataSource, NYPLFacetViewDelegate, UICollectionViewDataSource,
   UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic) FacetShow activeFacetShow;
@property (nonatomic) FacetSort activeFacetSort;
@property (nonatomic) NSArray *books;
@property (nonatomic) NYPLFacetBarView *facetBarView;
@property (nonatomic) UILabel *instructionsLabel;
@property (nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic) UIBarButtonItem *searchButton;
@property (nonatomic) NYPLMyBooksContainerView *containerView;

@end

@implementation NYPLMyBooksViewController

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;

  self.title = NSLocalizedString(@"MyBooksViewControllerTitle", nil);
  
  [self willReloadCollectionViewData];
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(bookRegistryDidChange)
   name:NYPLBookRegistryDidChangeNotification
   object:nil];
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(syncEnded)
   name:NSNotification.NYPLSyncEnded object:nil];
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(syncBegan)
   name:NSNotification.NYPLSyncBegan object:nil];
  
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
  
  self.activeFacetShow = FacetShowAll;
  self.activeFacetSort = FacetSortAuthor;
  
  self.collectionView.dataSource = self;
  self.collectionView.delegate = self;

  self.collectionView.alwaysBounceVertical = YES;
  self.refreshControl = [[UIRefreshControl alloc] init];
  [self.refreshControl addTarget:self action:@selector(didPullToRefresh) forControlEvents:UIControlEventValueChanged];
  [self.collectionView addSubview:self.refreshControl];
  
  self.facetBarView = [[NYPLFacetBarView alloc] initWithOrigin:CGPointZero width:0];
  self.facetBarView.facetView.dataSource = self;
  self.facetBarView.facetView.delegate = self;
  [self.view addSubview:self.facetBarView];
  [self.facetBarView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
  [self.facetBarView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
  [self.facetBarView autoPinToTopLayoutGuideOfViewController:self withInset:0.0];
  
  self.instructionsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  self.instructionsLabel.hidden = YES;
  self.instructionsLabel.text = NSLocalizedString(@"MyBooksGoToCatalog", nil);
  self.instructionsLabel.textAlignment = NSTextAlignmentCenter;
  self.instructionsLabel.textColor = [UIColor colorWithWhite:0.6667 alpha:1.0];
  self.instructionsLabel.numberOfLines = 0;
  [self.view addSubview:self.instructionsLabel];
  [self.instructionsLabel autoCenterInSuperview];
  [self.instructionsLabel autoSetDimension:ALDimensionWidth toSize:300.0];
  
  self.searchButton = [[UIBarButtonItem alloc]
                       initWithImage:[UIImage imageNamed:@"Search"]
                       style:UIBarButtonItemStylePlain
                       target:self
                       action:@selector(didSelectSearch)];
  self.searchButton.accessibilityLabel = NSLocalizedString(@"Search", nil);
  self.navigationItem.rightBarButtonItem = self.searchButton;

  // prevent possible unusable Search box when going to Search page
  self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
                                           initWithTitle:NSLocalizedString(@"Back", @"Back button text")
                                           style:UIBarButtonItemStylePlain
                                           target:nil action:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    BOOL isSyncing = [NYPLBookRegistry sharedRegistry].syncing;
    if(!isSyncing) {
      [self.refreshControl endRefreshing];
      [[NSNotificationCenter defaultCenter] postNotificationName:NSNotification.NYPLSyncEnded object:nil];
    } else {
      self.navigationItem.leftBarButtonItem.enabled = NO;
    }
  }];
  [self.navigationController setNavigationBarHidden:NO];
}

- (void)viewWillLayoutSubviews
{
  UIEdgeInsets contentInset = self.collectionView.contentInset;
  if (@available(iOS 11.0, *)) {
    // In iOS >= 11.0, we only need to account for our custom views.
    contentInset.top = CGRectGetHeight(self.facetBarView.frame);
  } else {
    // In older versions of iOS, we need to account for everything.
    contentInset.top = CGRectGetMaxY(self.facetBarView.frame);
  }
  self.collectionView.contentInset = contentInset;
  self.collectionView.scrollIndicatorInsets = contentInset;
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
  
  NSArray *books = [[NYPLBookRegistry sharedRegistry] myBooks];
  
  self.instructionsLabel.hidden = !!books.count;
  
  switch(self.activeFacetShow) {
    case FacetShowAll:
      break;
    case FacetShowOnLoan:
      books = [books filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NYPLBook *book, __unused NSDictionary *bindings) {
        return book.revokeURL != nil;
      }]];
      break;
  }
  
  switch(self.activeFacetSort) {
    case FacetSortAuthor: {
      self.books = [books sortedArrayUsingComparator:
                    ^NSComparisonResult(NYPLBook *const a, NYPLBook *const b) {
                      return [a.authors compare:b.authors options:NSCaseInsensitiveSearch];
                    }];
      break;
    }
    case FacetSortTitle: {
      self.books = [books sortedArrayUsingComparator:
                    ^NSComparisonResult(NYPLBook *const a, NYPLBook *const b) {
                      return [a.title compare:b.title options:NSCaseInsensitiveSearch];
                    }];
      break;
    }
  }
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

- (void)facetView:(NYPLFacetView *const)facetView
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
  
  [facetView reloadData];
  [self willReloadCollectionViewData];
  [self.collectionView reloadData];
}

#pragma mark -

- (void)didPullToRefresh
{
  if ([NYPLUserAccount sharedAccount].needsAuth) {
    if([[NYPLUserAccount sharedAccount] hasCredentials]) {
      [[NYPLBookRegistry sharedRegistry] syncWithStandardAlertsOnCompletion];
    } else {
      [NYPLAccountSignInViewController requestCredentialsWithCompletion:nil];
      [self.refreshControl endRefreshing];
      [[NSNotificationCenter defaultCenter] postNotificationName:NSNotification.NYPLSyncEnded object:nil];
    }
  } else {
    [[NYPLBookRegistry sharedRegistry] justLoad];
    [[NSNotificationCenter defaultCenter] postNotificationName:NSNotification.NYPLSyncEnded object:nil];
  }
}

- (void)bookRegistryDidChange
{
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    if([NYPLBookRegistry sharedRegistry].syncing == NO) {
      [self.refreshControl endRefreshing];
    }
  }];
}

- (void)didSelectSearch
{
  NSString *title = NSLocalizedString(@"MyBooksViewControllerSearchTitle", nil);
  NYPLOpenSearchDescription *searchDescription = [[NYPLOpenSearchDescription alloc] initWithTitle:title books:self.books];
  [self.navigationController
   pushViewController:[[NYPLCatalogSearchViewController alloc] initWithOpenSearchDescription:searchDescription]
   animated:YES];
}

- (void)syncBegan
{
  self.navigationItem.leftBarButtonItem.enabled = NO;
}

- (void)syncEnded
{
  self.navigationItem.leftBarButtonItem.enabled = YES;
}

- (void)viewWillTransitionToSize:(CGSize)__unused size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)__unused coordinator
{
  [self.collectionView reloadData];
}

@end
