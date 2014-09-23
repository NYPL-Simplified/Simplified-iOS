#import "NYPLBook.h"
#import "NYPLBookCell.h"
#import "NYPLBookDownloadingCell.h"
#import "NYPLConfiguration.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLMyBooksRegistry.h"

#import "NYPLBookCellCollectionViewController.h"

@interface NYPLBookCellCollectionViewController ()

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
  
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
  
  self.collectionView = [[UICollectionView alloc]
                         initWithFrame:self.view.bounds
                         collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
  NYPLBookCellRegisterClassesForCollectionView(self.collectionView);
  self.collectionView.alwaysBounceVertical = YES;
  self.collectionView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                          UIViewAutoresizingFlexibleHeight);
  self.collectionView.backgroundColor = [NYPLConfiguration backgroundColor];
  [self.view addSubview:self.collectionView];
  
  [[NSNotificationCenter defaultCenter]
   addObserverForName:NYPLBookRegistryDidChangeNotification
   object:nil
   queue:[NSOperationQueue mainQueue]
   usingBlock:^(__attribute__((unused)) NSNotification *note) {
     [self willReloadCollectionViewData];
     [self.collectionView reloadData];
   }];
  
  [[NSNotificationCenter defaultCenter]
   addObserverForName:NYPLMyBooksDownloadCenterDidChangeNotification
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
   }];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
  if(UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
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
  
  self.collectionView.hidden = YES;
  
  [coordinator
   animateAlongsideTransition:nil
   completion:^(__attribute__((unused)) id<UIViewControllerTransitionCoordinatorContext> context) {
     self.collectionView.contentOffset = CGPointMake(self.collectionView.contentOffset.x, y);
     [self.collectionView.collectionViewLayout invalidateLayout];
     self.collectionView.hidden = NO;
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
