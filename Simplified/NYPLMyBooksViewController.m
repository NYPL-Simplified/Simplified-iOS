#import "NYPLBookCell.h"
#import "NYPLBookDetailViewController.h"
#import "NYPLBookRegistry.h"

#import "NYPLMyBooksViewController.h"

@interface NYPLMyBooksViewController ()
  <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic) NSArray *books;
@property (nonatomic) UICollectionView *collectionView;

@end

static NSString *const reuseIdentifier = @"NYPLMyBooksViewControllerCell";

@implementation NYPLMyBooksViewController

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;

  self.title = NSLocalizedString(@"MyBooksViewControllerTitle", nil);
  
  [self updateBooks];
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(bookRegistryDidChange:)
   name:NYPLBookRegistryDidChange
   object:nil];
  
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  self.view.backgroundColor = [UIColor whiteColor];
  
  self.collectionView = [[UICollectionView alloc]
                         initWithFrame:self.view.bounds
                         collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
  self.collectionView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                          UIViewAutoresizingFlexibleHeight);
  self.collectionView.dataSource = self;
  self.collectionView.delegate = self;
  [self.collectionView registerClass:[NYPLBookCell class]
          forCellWithReuseIdentifier:reuseIdentifier];
  self.collectionView.backgroundColor = [UIColor whiteColor];
  [self.view addSubview:self.collectionView];
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(__attribute__((unused)) UICollectionView *const)collectionView
didSelectItemAtIndexPath:(__attribute__((unused)) NSIndexPath *const)indexPath
{
  // TODO
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
  sizeForItemAtIndexPath:(__attribute__((unused)) NSIndexPath *)indexPath
{
  return NYPLBookCellSizeForIdiomAndOrientation(UI_USER_INTERFACE_IDIOM(),
                                                self.interfaceOrientation);
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
  NYPLBookCell *const cell = [collectionView
                              dequeueReusableCellWithReuseIdentifier:reuseIdentifier
                              forIndexPath:indexPath];
  
  assert([cell isKindOfClass:[NYPLBookCell class]]);
  
  [cell setBook:self.books[indexPath.row]];
  
  return cell;
}

#pragma mark -

- (void)updateBooks
{
  self.books = [[NYPLBookRegistry sharedRegistry]
                allBooksSortedByBlock:^NSComparisonResult(NYPLBook *const a, NYPLBook *const b) {
                  return [a.title compare:b.title options:NSCaseInsensitiveSearch];
                }];
}

- (void)bookRegistryDidChange:(__attribute__((unused)) NSNotification *)notification
{
  [self updateBooks];
  [self.collectionView reloadData];
}

@end
