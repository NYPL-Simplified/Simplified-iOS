#import "NYPLCatalogBook.h"
#import "NYPLCatalogCategory.h"
#import "NYPLCatalogCategoryCell.h"

#import "NYPLCatalogCategoryViewController.h"

@interface NYPLCatalogCategoryViewController ()
  <NYPLCatalogCategoryDelegate, UICollectionViewDataSource, UICollectionViewDelegate,
   UICollectionViewDelegateFlowLayout>

@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic) NYPLCatalogCategory *category;
@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) NSURL *url;

@end

static NSString *const reuseIdentifier = @"NYPLCatalogCategoryViewControllerCell";

@implementation NYPLCatalogCategoryViewController

- (instancetype)initWithURL:(NSURL *const)url title:(NSString *const)title
{
  self = [super init];
  if(!self) return nil;
  
  self.url = url;
  
  self.title = title;
  
  self.view.backgroundColor = [UIColor whiteColor];
  
  return self;
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  self.collectionView = [[UICollectionView alloc]
                         initWithFrame:self.view.bounds
                         collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
  self.collectionView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                          UIViewAutoresizingFlexibleHeight);
  self.collectionView.dataSource = self;
  self.collectionView.delegate = self;
  [self.collectionView registerClass:[NYPLCatalogCategoryCell class]
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
   withURL:self.url
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
            NSLocalizedString(@"CatalogCategoryViewControllerFeedDownloadFailedMessage", nil)
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

-(void)willRotateToInterfaceOrientation:(__attribute__((unused)) UIInterfaceOrientation)orientation
                               duration:(__attribute__((unused)) NSTimeInterval)duration
{
  [self.collectionView.collectionViewLayout invalidateLayout];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(__attribute__((unused)) UICollectionView *)collectionView
     numberOfItemsInSection:(__attribute__((unused)) NSInteger)section
{
  return self.category.books.count;
}

// TODO: This test method needs to be replaced with one that returns the correct cell.
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  UICollectionViewCell *const cell = [collectionView
                                      dequeueReusableCellWithReuseIdentifier:reuseIdentifier
                                      forIndexPath:indexPath];
  
  UILabel *const label = [[UILabel alloc] init];
  label.text = ((NYPLCatalogBook *) self.category.books[indexPath.row]).title;
  label.frame = cell.contentView.bounds;
  for(UIView *const view in [[cell contentView] subviews]) {
    [view removeFromSuperview];
  }
  [cell.contentView addSubview:label];
  
  cell.backgroundColor = [UIColor colorWithHue:([label.text hash] / (CGFloat) ULONG_MAX)
                                    saturation:1.0
                                    brightness:1.0
                                         alpha:1.0];
  
  [self.category prepareForBookIndex:indexPath.row];
  
  return cell;
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
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  // FIXME: This size calulation is extremely ad-hoc.
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    switch(self.interfaceOrientation) {
      case UIInterfaceOrientationPortrait:
        // fallthrough
      case UIInterfaceOrientationPortraitUpsideDown:
        return CGSizeMake(384, 120);
      case UIInterfaceOrientationLandscapeLeft:
        // fallthrough
      case UIInterfaceOrientationLandscapeRight:
        if(indexPath.row % 3 == 0) {
          return CGSizeMake(342, 120);
        } else {
          return CGSizeMake(341, 120);
        }
    }
  } else {
    return CGSizeMake(320, 120);;
  }
}

#pragma mark NYPLCatalogCategoryDelegate

- (void)catalogCategory:(__attribute__((unused)) NYPLCatalogCategory *)catalogCategory
         didUpdateBooks:(__attribute__((unused)) NSArray *)books
{
  [self.collectionView reloadData];
}

#pragma mark -

- (void)didLoadCategory
{
  [self.collectionView reloadData];
  self.collectionView.hidden = NO;
}

@end
