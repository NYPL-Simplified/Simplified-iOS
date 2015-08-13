#import "NYPLAccount.h"
#import "NYPLBookCell.h"
#import "NYPLBookDetailViewController.h"
#import "NYPLBookRegistry.h"
#import "NYPLConfiguration.h"
#import "NYPLSettingsAccountViewController.h"

#import "NYPLHoldsViewController.h"

@interface NYPLHoldsViewController ()
<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic) NSArray *books;
@property (nonatomic) UIBarButtonItem *syncButton;
@property (nonatomic) UIBarButtonItem *syncInProgressButton;

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

#pragma mark UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
  
  self.collectionView.dataSource = self;
  self.collectionView.delegate = self;
  
  self.syncButton = [[UIBarButtonItem alloc]
                     initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                     target:self
                     action:@selector(didSelectSync)];
  self.navigationItem.rightBarButtonItem = self.syncButton;
  
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
    self.navigationItem.rightBarButtonItem = self.syncInProgressButton;
  } else {
    self.navigationItem.rightBarButtonItem = self.syncButton;
  }
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
  
  self.books = [[NYPLBookRegistry sharedRegistry] heldBooks];
}

#pragma mark -

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
      self.navigationItem.rightBarButtonItem = self.syncInProgressButton;
    } else {
      self.navigationItem.rightBarButtonItem = self.syncButton;
    }
  }];
}

@end
