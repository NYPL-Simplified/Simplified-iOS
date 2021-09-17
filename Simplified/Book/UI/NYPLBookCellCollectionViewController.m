#import "NYPLBook.h"
#import "NYPLBookCell.h"
#import "NYPLBookDownloadingCell.h"
#import "NYPLBookRegistry.h"
#import "NYPLConfiguration.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "UIView+NYPLViewAdditions.h"
#import "NYPLBookCellCollectionViewController.h"
#import "SimplyE-Swift.h"

@interface NYPLBookCellCollectionViewController () <UICollectionViewDelegateFlowLayout>

@property (nonatomic) NSMutableArray *observers;

@end

@implementation NYPLBookCellCollectionViewController

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.observers = [NSMutableArray array];
  
  return self;
}

- (void)dealloc
{
  for(id const observer in self.observers) {
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
  }
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.view.backgroundColor = [NYPLConfiguration defaultBackgroundColor];
  
  self.collectionView = [[UICollectionView alloc]
                         initWithFrame:self.view.bounds
                         collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
  NYPLBookCellRegisterClassesForCollectionView(self.collectionView);
  self.collectionView.alwaysBounceVertical = YES;
  self.collectionView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                          UIViewAutoresizingFlexibleHeight);
  self.collectionView.backgroundColor = [NYPLConfiguration defaultBackgroundColor];
  [self.view addSubview:self.collectionView];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  // Notifications are installed so the view will update while visible.
  [self.observers addObject:
   [[NSNotificationCenter defaultCenter]
    addObserverForName:NSNotification.NYPLBookRegistryDidChange
    object:nil
    queue:[NSOperationQueue mainQueue]
    usingBlock:^(__attribute__((unused)) NSNotification *note) {
      [self willReloadCollectionViewData];
      [self.collectionView reloadData];
    }]];
  
  [self.observers addObject:
   [[NSNotificationCenter defaultCenter]
    addObserverForName:NSNotification.NYPLMyBooksDownloadCenterDidChange
    object:nil
    queue:[NSOperationQueue mainQueue]
    usingBlock:^(__attribute__((unused)) NSNotification *note) {
      for(UICollectionViewCell *const cell in [self.collectionView visibleCells]) {
        if([cell isKindOfClass:[NYPLBookDownloadingCell class]]) {
          NYPLBookDownloadingCell *const downloadingCell = (NYPLBookDownloadingCell *)cell;
          NSString *const bookIdentifier = downloadingCell.book.identifier;
          downloadingCell.downloadProgress = [[NYPLMyBooksDownloadCenter sharedDownloadCenter]
                                              downloadProgressForBookIdentifier:bookIdentifier];
        }
      }
    }]];
  
  // We must reload data because prior notifications may have been missed.
  [self willReloadCollectionViewData];
  [self.collectionView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  
  // Updates are not necessary when the view is not being shown.
  for(id const observer in self.observers) {
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
  }
  
  [self.observers removeAllObjects];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{  
  if(self.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassRegular) {
    return;
  }
  
  NSInteger const currentColumns =
  NYPLBookCellColumnCountForCollectionViewWidth(CGRectGetWidth(self.collectionView.bounds));
  
  NSInteger const newColumns =
  NYPLBookCellColumnCountForCollectionViewWidth(size.width);
  
  if(currentColumns == newColumns) {
    return;
  }
  
  CGFloat columnRatio = currentColumns / (CGFloat)newColumns;
  
  CGFloat top = self.collectionView.contentInset.top;
  
  CGFloat const y = (self.collectionView.contentOffset.y + top) * columnRatio - top;
  
  // We place a view over the collection view to avoid changing properties (e.g. |hidden|) that may
  // inadvertently alter the intended behavior of subclasses. Attempting to save the property and
  // then reset it to its previous state in the completion block would give rise to race conditions.
  UIView *const shieldView = [[UIView alloc] initWithFrame:self.collectionView.frame];
  shieldView.backgroundColor = [NYPLConfiguration defaultBackgroundColor];
  shieldView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
  [self.view addSubview:shieldView];
  UIActivityIndicatorView *const activityIndicatorView =
    [[UIActivityIndicatorView alloc]
     initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  activityIndicatorView.center = shieldView.center;
  [activityIndicatorView integralizeFrame];
  activityIndicatorView.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin |
                                            UIViewAutoresizingFlexibleRightMargin |
                                            UIViewAutoresizingFlexibleBottomMargin |
                                            UIViewAutoresizingFlexibleLeftMargin);
  [activityIndicatorView startAnimating];
  [shieldView addSubview:activityIndicatorView];
  
  [coordinator
   animateAlongsideTransition:nil
   completion:^(__attribute__((unused)) id<UIViewControllerTransitionCoordinatorContext> context) {
     self.collectionView.contentOffset = CGPointMake(self.collectionView.contentOffset.x, y);
     [self.collectionView.collectionViewLayout invalidateLayout];
     [shieldView removeFromSuperview];
   }];
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
  sizeForItemAtIndexPath:(NSIndexPath *const)indexPath
{
  return NYPLBookCellSize(indexPath, CGRectGetWidth(self.view.bounds));
}

#pragma mark -

- (void)willReloadCollectionViewData
{
  
}

@end
