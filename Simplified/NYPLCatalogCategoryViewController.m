#import "NYPLAccount.h"
#import "NYPLBook.h"
#import "NYPLBookCell.h"
#import "NYPLBookDetailController.h"
#import "NYPLCatalogCategory.h"
#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLMyBooksRegistry.h"
#import "NYPLSettingsCredentialViewController.h"

#import "NYPLCatalogCategoryViewController.h"

@interface NYPLCatalogCategoryViewController ()
  <NYPLBookCellDelegate, NYPLCatalogCategoryDelegate, UICollectionViewDataSource,
   UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic) NYPLCatalogCategory *category;
@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) NSURL *URL;

@end

static NSString *const reuseIdentifier = @"NYPLCatalogCategoryViewControllerCell";

@implementation NYPLCatalogCategoryViewController

- (instancetype)initWithURL:(NSURL *const)URL
                      title:(NSString *const)title
{
  self = [super init];
  if(!self) return nil;
  
  self.URL = URL;
  
  self.title = title;
  
  self.view.backgroundColor = [UIColor whiteColor];
  
  [[NSNotificationCenter defaultCenter]
   addObserverForName:NYPLBookRegistryDidChange
   object:nil
   queue:[NSOperationQueue mainQueue]
   usingBlock:^(__attribute__((unused)) NSNotification *note) {
     [self.collectionView reloadData];
   }];
  
  [[NSNotificationCenter defaultCenter]
   addObserverForName:NYPLMyBooksDownloadCenterDidChange
   object:nil
   queue:[NSOperationQueue mainQueue]
   usingBlock:^(__attribute__((unused)) NSNotification *note) {
     // Rather than reload the collection view as this block used to, we now simply update progress
     // for visible cells instead. This change was made because constantly reloading the table
     // resulted in cells shuffling around due to cell reuse. While said shuffling caused no visual
     // problems because all states were reset appropropriately, it did cause problems with touch
     // detection because any touch spanning a reload would cause the button to fail to fire its
     // "touch up inside" event upon release. This approach is also quite a bit more efficient than
     // constantly reloading.
     for(NYPLBookCell *const cell in [self.collectionView visibleCells]) {
       cell.downloadProgress = [[NYPLMyBooksDownloadCenter sharedDownloadCenter]
                                downloadProgressForBookIdentifier:cell.book.identifier];
     }
   }];
  
  return self;
}

#pragma mark NSObject

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
  self.collectionView.hidden = YES;
  [self.view addSubview:self.collectionView];
  
  self.activityIndicatorView = [[UIActivityIndicatorView alloc]
                                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  [self.activityIndicatorView startAnimating];
  [self.view addSubview:self.activityIndicatorView];
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  [NYPLCatalogCategory
   withURL:self.URL
   handler:^(NYPLCatalogCategory *const category) {
     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
       self.activityIndicatorView.hidden = YES;
       [self.activityIndicatorView stopAnimating];
       [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
       
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
       [self didLoadCategory];
     }];
   }];
}

- (void)viewWillLayoutSubviews
{
  self.activityIndicatorView.center = self.view.center;
}

// The approach taken in this method was settled upon after several other approaches were tried.
// It's not generic because it assumes two columns in portrait and three in landscape when using an
// iPad, and it assumes row heights are constant, but it's simple and exact.
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
  NYPLBookCell *const cell = [collectionView
                              dequeueReusableCellWithReuseIdentifier:reuseIdentifier
                              forIndexPath:indexPath];
  
  assert([cell isKindOfClass:[NYPLBookCell class]]);
  
  NYPLBook *const book = self.category.books[indexPath.row];
  
  cell.book = book;
  cell.delegate = self;
  cell.state = [[NYPLMyBooksRegistry sharedRegistry] stateForIdentifier:book.identifier];
  cell.downloadProgress = [[NYPLMyBooksDownloadCenter sharedDownloadCenter]
                           downloadProgressForBookIdentifier:book.identifier];
  
  [self.category prepareForBookIndex:indexPath.row];
  
  return cell;
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(__attribute__((unused)) UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *const)indexPath
{
  NYPLBook *const book = self.category.books[indexPath.row];
  
  [[NYPLBookDetailController sharedController] displayBook:book fromViewController:self];
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

#pragma mark NYPLBookCellDelegate

- (void)didSelectDownloadForBookCell:(NYPLBookCell *const)cell
{
  NYPLBook *const book = cell.book;

  if([NYPLAccount sharedAccount].hasBarcodeAndPIN) {
    [[NYPLMyBooksDownloadCenter sharedDownloadCenter] startDownloadForBook:book];
  } else {
    [[NYPLSettingsCredentialViewController sharedController]
     requestCredentialsFromViewController:self
     useExistingBarcode:NO
     message:NYPLSettingsCredentialViewControllerMessageLogInToDownloadBook
     completionHandler:^{
       [[NYPLMyBooksDownloadCenter sharedDownloadCenter] startDownloadForBook:book];
     }];
  }
}

#pragma mark -

- (void)didLoadCategory
{
  [self.collectionView reloadData];
  self.collectionView.hidden = NO;
}

@end
