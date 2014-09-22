#import "NYPLBook.h"
#import "NYPLBookCell.h"
#import "NYPLBookDetailViewController.h"
#import "NYPLConfiguration.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLMyBooksRegistry.h"

#import "NYPLMyBooksViewController.h"

@interface NYPLMyBooksViewController ()
  <NYPLBookCellDelegate, UICollectionViewDataSource, UICollectionViewDelegate,
   UICollectionViewDelegateFlowLayout>

@property (nonatomic) NSArray *books;
@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) NSMutableArray *observers;

@end

@implementation NYPLMyBooksViewController

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;

  self.title = NSLocalizedString(@"MyBooksViewControllerTitle", nil);
  
  self.observers = [NSMutableArray array];
  
  [self.observers addObject:
   [[NSNotificationCenter defaultCenter]
    addObserverForName:NYPLBookRegistryDidChangeNotification
    object:nil
    queue:[NSOperationQueue mainQueue]
    usingBlock:^(__attribute__((unused)) NSNotification *note) {
      [self updateBooks];
      [self.collectionView reloadData];
    }]];
  
  [self.observers addObject:
   [[NSNotificationCenter defaultCenter]
    addObserverForName:NYPLMyBooksDownloadCenterDidChangeNotification
    object:nil
    queue:[NSOperationQueue mainQueue]
    usingBlock:^(__attribute__((unused)) NSNotification *note) {
      [self updateBooks];
      [self.collectionView reloadData];
    }]];
  
  [self updateBooks];
  
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
  [self.observers addObjectsFromArray:
   NYPLBookCellRegisterNotificationsForCollectionView(self.collectionView)];
  self.collectionView.alwaysBounceVertical = YES;
  self.collectionView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                          UIViewAutoresizingFlexibleHeight);
  self.collectionView.dataSource = self;
  self.collectionView.delegate = self;
  self.collectionView.backgroundColor = [NYPLConfiguration backgroundColor];
  [self.view addSubview:self.collectionView];
}

// FIXME: This code duplicates code in NYPLCatalogCategoryController and should be factored out.
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

#pragma mark UICollectionViewDelegate

- (void)collectionView:(__attribute__((unused)) UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *const)indexPath
{
  NYPLBook *const book = self.books[indexPath.row];
  
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
                   layout:(__attribute__((unused)) UICollectionViewLayout*)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(__attribute__((unused)) NSInteger)section
{
  return 0.0;
}

- (CGFloat)collectionView:(__attribute__((unused)) UICollectionView *)collectionView
                   layout:(__attribute__((unused)) UICollectionViewLayout*)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(__attribute__((unused)) NSInteger)section
{
  return 0.0;
}

- (CGSize)collectionView:(__attribute__((unused)) UICollectionView *)collectionView
                  layout:(__attribute__((unused)) UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *const)indexPath
{
  return NYPLBookCellSize(UI_USER_INTERFACE_IDIOM(), self.interfaceOrientation, indexPath);
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

#pragma mark -

- (void)updateBooks
{
  self.books = [[[NYPLMyBooksRegistry sharedRegistry] allBooks] sortedArrayUsingComparator:
                ^NSComparisonResult(NYPLBook *const a, NYPLBook *const b) {
                  return [a.title compare:b.title options:NSCaseInsensitiveSearch];
                }];
}

@end
