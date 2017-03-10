#import "NYPLAccount.h"
#import "NYPLBook.h"
#import "NYPLBookCell.h"
#import "NYPLBookDetailViewController.h"
#import "NYPLBookRegistry.h"
#import "NYPLCatalogSearchViewController.h"
#import "NYPLConfiguration.h"
#import "NYPLOpenSearchDescription.h"
#import "NYPLSettings.h"
#import "NYPLAccountSignInViewController.h"
#import <PureLayout/PureLayout.h>
#import "UIView+NYPLViewAdditions.h"

#import "NYPLHoldsViewController.h"

#import "SimplyE-Swift.h"

@interface NYPLHoldsViewController ()
<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic) NSArray *reservedBooks;
@property (nonatomic) NSArray *heldBooks;
@property (nonatomic) UILabel *instructionsLabel;
@property (nonatomic) UIRefreshControl *refreshControl;
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
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(syncEnded)
   name:NYPLSyncEndedNotification object:nil];
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(syncBegan)
   name:NYPLSyncBeganNotification object:nil];

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
  
  self.collectionView.alwaysBounceVertical = YES;
  self.refreshControl = [[UIRefreshControl alloc] init];
  [self.refreshControl addTarget:self action:@selector(didSelectSync) forControlEvents:UIControlEventValueChanged];
  [self.collectionView addSubview:self.refreshControl];
  
  // We know that super sets it to a flow layout.
  UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
  layout.headerReferenceSize = CGSizeMake(0, 20);
  
  self.instructionsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  self.instructionsLabel.hidden = YES;
  self.instructionsLabel.text = NSLocalizedString(@"ReservationsGoToCatalog", nil);
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
  
  if([NYPLBookRegistry sharedRegistry].syncing == NO) {
    [self.refreshControl endRefreshing];
    [[NSNotificationCenter defaultCenter] postNotificationName:NYPLSyncEndedNotification object:nil];
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
  
  self.instructionsLabel.hidden = !!books.count;
  
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
  [[NSNotificationCenter defaultCenter] postNotificationName:NYPLSyncBeganNotification object:nil];
  
  Account *account = [[NYPLSettings sharedSettings] currentAccount];
  
  if (account.needsAuth)
  {

    if([[NYPLAccount sharedAccount] hasBarcodeAndPIN]) {
      [[NYPLBookRegistry sharedRegistry] syncWithCompletionHandler:^(BOOL success) {
        if(success) {
          [[NYPLBookRegistry sharedRegistry] save];
        } else {
          [[[UIAlertView alloc]
            initWithTitle:NSLocalizedString(@"SyncFailed", nil)
            message:NSLocalizedString(@"CheckConnection", nil)
            delegate:nil
            cancelButtonTitle:nil
            otherButtonTitles:NSLocalizedString(@"OK", nil), nil]
           show];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:NYPLSyncEndedNotification object:nil];
      }];
    } else {
      // We can't sync if we're not logged in, so let's log in. We don't need a completion handler
      // here because logging in will trigger a sync anyway. The only downside of letting the sync
      // happen elsewhere is that the user will not receive an error if the sync fails because it will
      // be considered an automatic sync and not a manual sync.
      // TODO: We should make this into a manual sync while somehow avoiding double-syncing.
      [NYPLAccountSignInViewController
       requestCredentialsUsingExistingBarcode:NO
       completionHandler:nil];
      [self.refreshControl endRefreshing];
      [[NSNotificationCenter defaultCenter] postNotificationName:NYPLSyncEndedNotification object:nil];
    }
  }
  else
  {
    [[NYPLBookRegistry sharedRegistry] justLoad];
    [[NSNotificationCenter defaultCenter] postNotificationName:NYPLSyncEndedNotification object:nil];
    
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
  NSString *title = NSLocalizedString(@"HoldsViewControllerSearchTitle", nil);
  NYPLOpenSearchDescription *searchDescription = [[NYPLOpenSearchDescription alloc] initWithTitle:title books:[[NYPLBookRegistry sharedRegistry] heldBooks]];
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

@end
