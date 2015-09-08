#import "NYPLAccount.h"
#import "NYPLBook.h"
#import "NYPLBookCell.h"
#import "NYPLBookDetailViewController.h"
#import "NYPLBookRegistry.h"
#import "NYPLCatalogSearchViewController.h"
#import "NYPLConfiguration.h"
#import "NYPLOpenSearchDescription.h"
#import "NYPLSettingsAccountViewController.h"

#import "NYPLHoldsViewController.h"

@interface NYPLHoldsViewController ()
<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic) NSArray *reservedBooks;
@property (nonatomic) NSArray *heldBooks;
@property (nonatomic) UIBarButtonItem *syncButton;
@property (nonatomic) UIBarButtonItem *syncInProgressButton;
@property (nonatomic) UIBarButtonItem *searchButton;

@end

@implementation NYPLHoldsViewController

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;

  self.title = NSLocalizedString(@"HoldsViewControllerTitle", nil);
  
  [self willReloadCollectionViewData];
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(bookRegistryDidChange)
   name:NYPLBookRegistryDidChangeNotification
   object:nil];
  
  return self;
}

- (NSArray *)bookArrayForSection:(NSInteger)section
{
  if (self.reservedBooks.count > 0) {
    return section == 0 ? self.reservedBooks : self.heldBooks;
  } else {
    return self.heldBooks;
  }
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
  
  self.collectionView.dataSource = self;
  self.collectionView.delegate = self;
  [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
  // We know that super sets it to a flow layout.
  UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
  layout.headerReferenceSize = CGSizeMake(0, 20);
  
  self.syncButton = [[UIBarButtonItem alloc]
                     initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                     target:self
                     action:@selector(didSelectSync)];
  self.navigationItem.leftBarButtonItem = self.syncButton;
  
  self.searchButton = [[UIBarButtonItem alloc]
                       initWithImage:[UIImage imageNamed:@"Search"]
                       style:UIBarButtonItemStylePlain
                       target:self
                       action:@selector(didSelectSearch)];
  self.navigationItem.rightBarButtonItem = self.searchButton;
  
  UIActivityIndicatorView *const activityIndicatorView =
  [[UIActivityIndicatorView alloc]
   initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  [activityIndicatorView sizeToFit];
  activityIndicatorView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                            UIViewAutoresizingFlexibleHeight);
  [activityIndicatorView startAnimating];
  self.syncInProgressButton = [[UIBarButtonItem alloc]
                               initWithCustomView:activityIndicatorView];
  self.syncInProgressButton.enabled = NO;
  
  if([NYPLBookRegistry sharedRegistry].syncing) {
    self.navigationItem.leftBarButtonItem = self.syncInProgressButton;
  } else {
    self.navigationItem.leftBarButtonItem = self.syncButton;
  }
}

#pragma mark UICollectionViewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(__attribute__((unused)) UICollectionView *)collectionView
{
  NSInteger sections = 0;
  if (self.reservedBooks.count > 0) {
    sections++;
  }
  if(self.heldBooks.count > 0) {
    sections++;
  }
  return sections;
}

- (void)collectionView:(__attribute__((unused)) UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *const)indexPath
{
  NYPLBook *const book = [self bookArrayForSection:indexPath.section][indexPath.row];
  
  [[[NYPLBookDetailViewController alloc] initWithBook:book] presentFromViewController:self];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(__attribute__((unused)) UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
  return [self bookArrayForSection:section].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  NYPLBook *const book = [self bookArrayForSection:indexPath.section][indexPath.row];
  
  return NYPLBookCellDequeue(collectionView, indexPath, book);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath
{
  UICollectionReusableView *view = nil;
  if(kind == UICollectionElementKindSectionHeader) {
    view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
    CGRect viewFrame = view.frame;
    viewFrame.size = CGSizeMake(collectionView.frame.size.width, 20);
    view.frame = viewFrame;
    UILabel *title = view.subviews.count > 0 ? view.subviews[0] : nil;
    if(!title) {
      title = [[UILabel alloc] init];
      title.textColor = [UIColor whiteColor];
      title.font = [UIFont systemFontOfSize:12];
      [view addSubview:title];
    }
    if([self bookArrayForSection:indexPath.section] == self.reservedBooks) {
      view.layer.backgroundColor = [NYPLConfiguration mainColor].CGColor;
      title.text = NSLocalizedString(@"AvailableForCheckoutHeader", nil);
    } else {
      view.layer.backgroundColor = [UIColor colorWithRed:172.0/255.0 green:177.0/255.0 blue:182.0/255 alpha:1.0].CGColor;
      title.text = NSLocalizedString(@"WaitingForAvailabilityHeader", nil);
    }
    [title sizeToFit];
    CGRect frame = title.frame;
    frame.origin = CGPointMake(10, view.frame.size.height / 2 - frame.size.height / 2);
    title.frame = frame;
  } else {
    // This should never happen, but avoid crashing if it does.
    view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
    view.frame = CGRectZero;
  }
  return view;
}

#pragma mark NYPLBookCellCollectionViewController

- (void)willReloadCollectionViewData
{
  [super willReloadCollectionViewData];
  
  NSArray *books = [[NYPLBookRegistry sharedRegistry] heldBooks];
  NSMutableArray *reserved = [NSMutableArray array];
  NSMutableArray *held = [NSMutableArray array];
  for(NYPLBook *book in books) {
    if (book.availabilityStatus == NYPLBookAvailabilityStatusReady) {
      [reserved addObject:book];
    } else {
      [held addObject:book];
    }
  }
  self.heldBooks = held;
  self.reservedBooks = reserved;
  [self updateBadge];
}

#pragma mark -

- (void)updateBadge
{
  self.navigationController.tabBarItem.badgeValue = self.reservedBooks.count > 0 ? [@(self.reservedBooks.count) stringValue] : nil;
}

- (void)didSelectSync
{
  if([[NYPLAccount sharedAccount] hasBarcodeAndPIN]) {
    [[NYPLBookRegistry sharedRegistry] syncWithStandardAlertsOnCompletion];
  } else {
    // We can't sync if we're not logged in, so let's log in. We don't need a completion handler
    // here because logging in will trigger a sync anyway. The only downside of letting the sync
    // happen elsewhere is that the user will not receive an error if the sync fails because it will
    // be considered an automatic sync and not a manual sync.
    // TODO: We should make this into a manual sync while somehow avoiding double-syncing.
    [NYPLSettingsAccountViewController
     requestCredentialsUsingExistingBarcode:NO
     completionHandler:nil];
  }
}

- (void)bookRegistryDidChange
{
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    if([NYPLBookRegistry sharedRegistry].syncing) {
      self.navigationItem.leftBarButtonItem = self.syncInProgressButton;
    } else {
      self.navigationItem.leftBarButtonItem = self.syncButton;
    }
  }];
}

- (void)didSelectSearch
{
  NSString *title = NSLocalizedString(@"HoldsViewControllerSearchTitle", nil);
  NYPLOpenSearchDescription *searchDescription = [[NYPLOpenSearchDescription alloc] initWithTitle:title books:[[NYPLBookRegistry sharedRegistry] heldBooks]];
  [self.navigationController
   pushViewController:[[NYPLCatalogSearchViewController alloc] initWithOpenSearchDescription:searchDescription]
   animated:YES];
}

@end
