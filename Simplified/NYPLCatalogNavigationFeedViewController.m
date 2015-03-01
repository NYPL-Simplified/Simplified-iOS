#import "NYPLBookCoverRegistry.h"
#import "NYPLBookDetailViewController.h"
#import "NYPLCatalogAcquisitionFeedViewController.h"
#import "NYPLCatalogLane.h"
#import "NYPLCatalogLaneCell.h"
#import "NYPLCatalogNavigationFeed.h"
#import "NYPLCatalogSearchViewController.h"
#import "NYPLCatalogSubsectionLink.h"
#import "NYPLConfiguration.h"
#import "NYPLIndeterminateProgressView.h"
#import "NYPLReloadView.h"
#import "UIView+NYPLViewAdditions.h"

#import "NYPLCatalogNavigationFeedViewController.h"

static CGFloat const rowHeight = 115.0;
static CGFloat const sectionHeaderHeight = 50.0;

@interface NYPLCatalogNavigationFeedViewController ()
  <NYPLCatalogLaneCellDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic) NSMutableDictionary *bookIdentifiersToImages;
@property (nonatomic) NYPLCatalogNavigationFeed *catalogNavigationFeed;
@property (nonatomic) NSMutableDictionary *cachedLaneCells;
@property (nonatomic) NSUInteger indexOfNextLaneRequiringImageDownload;
@property (nonatomic) NYPLReloadView *reloadView;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSURL *URL;

@end

@implementation NYPLCatalogNavigationFeedViewController

#pragma mark NSObject

- (instancetype)initWithURL:(NSURL *const)URL title:(NSString *const)title
{
  self = [super init];
  if(!self) return nil;
  
  self.bookIdentifiersToImages = [NSMutableDictionary dictionary];
  self.cachedLaneCells = [NSMutableDictionary dictionary];
  self.title = title;
  self.URL = URL;
  
  return self;
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];

  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                            initWithImage:[UIImage imageNamed:@"Search"]
                                            style:UIBarButtonItemStylePlain
                                            target:self
                                            action:@selector(didSelectSearch)];
  
  self.navigationItem.rightBarButtonItem.enabled = NO;
  
  self.activityIndicatorView = [[UIActivityIndicatorView alloc]
                                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  [self.view addSubview:self.activityIndicatorView];
  
  self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
  self.tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight);
  self.tableView.backgroundColor = [NYPLConfiguration backgroundColor];
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.sectionHeaderHeight = sectionHeaderHeight;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.allowsSelection = NO;
  self.tableView.hidden = YES;
  [self.view addSubview:self.tableView];
  
  __weak NYPLCatalogNavigationFeedViewController *weakSelf = self;
  self.reloadView = [[NYPLReloadView alloc] init];
  self.reloadView.handler = ^{
    weakSelf.reloadView.hidden = YES;
    [weakSelf downloadFeed];
  };
  self.reloadView.hidden = YES;
  [self.view addSubview:self.reloadView];
  
  [self downloadFeed];
}

- (void)viewWillLayoutSubviews
{
  [self.activityIndicatorView centerInSuperview];
  [self.activityIndicatorView integralizeFrame];
  
  UIEdgeInsets const insets = UIEdgeInsetsMake(self.topLayoutGuide.length,
                                               0,
                                               self.bottomLayoutGuide.length,
                                               0);
  
  self.tableView.contentInset = insets;
  self.tableView.scrollIndicatorInsets = insets;
  
  [self.reloadView centerInSuperview];
  [self.reloadView integralizeFrame];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  
  [self.cachedLaneCells removeAllObjects];
}

#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(__attribute__((unused)) UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *const)indexPath
{
  // Caching cells helps with performance and lets us retain horizontal scroll positions. Cells are
  // only stored in |self.cachedLaneCells| if they are final.
  UITableViewCell *const cachedCell = self.cachedLaneCells[indexPath];
  if(cachedCell) {
    return cachedCell;
  }
  
  if(indexPath.section < (NSInteger) self.indexOfNextLaneRequiringImageDownload) {
    NYPLCatalogLaneCell *const cell =
      [[NYPLCatalogLaneCell alloc]
       initWithLaneIndex:indexPath.section
       books:((NYPLCatalogLane *) self.catalogNavigationFeed.lanes[indexPath.section]).books
       bookIdentifiersToImages:self.bookIdentifiersToImages];
    cell.delegate = self;
    self.cachedLaneCells[indexPath] = cell;
    return cell;
  } else {
    UITableViewCell *const cell = [[UITableViewCell alloc] init];
    CGRect const progressViewFrame = CGRectMake(5,
                                                0,
                                                CGRectGetWidth(cell.contentView.bounds) - 10,
                                                CGRectGetHeight(cell.contentView.bounds));
    NYPLIndeterminateProgressView *const progressView = [[NYPLIndeterminateProgressView alloc]
                                                         initWithFrame:progressViewFrame];
    progressView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight);
    progressView.color = [UIColor colorWithWhite:0.95 alpha:1.0];
    progressView.layer.borderWidth = 2;
    progressView.speedMultiplier = 2.0;
    [progressView startAnimating];
    [cell.contentView addSubview:progressView];
    return cell;
  }
}

- (NSInteger)tableView:(__attribute__((unused)) UITableView *)tableView
 numberOfRowsInSection:(__attribute__((unused)) NSInteger)section
{
  return 1;
}

- (NSInteger)numberOfSectionsInTableView:(__attribute__((unused)) UITableView *)tableView
{
  return self.catalogNavigationFeed.lanes.count;
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(__attribute__((unused)) UITableView *)tableView
heightForRowAtIndexPath:(__attribute__((unused)) NSIndexPath *)indexPath
{
  return rowHeight;
}

- (CGFloat)tableView:(__attribute__((unused)) UITableView *)tableView
heightForHeaderInSection:(__attribute__((unused)) NSInteger)section
{
  return sectionHeaderHeight;
}

- (UIView *)tableView:(__attribute__((unused)) UITableView *)tableView
viewForHeaderInSection:(NSInteger const)section
{
  CGRect const frame = CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), sectionHeaderHeight);
  UIView *const view = [[UIView alloc] initWithFrame:frame];
  view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  view.backgroundColor = [[NYPLConfiguration backgroundColor] colorWithAlphaComponent:0.9];
  
  {
    UIButton *const button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.titleLabel.font = [UIFont systemFontOfSize:21];
    NSString *const title = ((NYPLCatalogLane *) self.catalogNavigationFeed.lanes[section]).title;
    [button setTitle:title forState:UIControlStateNormal];
    [button sizeToFit];
    button.frame = CGRectMake(7, 5, CGRectGetWidth(button.frame), CGRectGetHeight(button.frame));
    button.tag = section;
    [button addTarget:self
               action:@selector(didSelectCategory:)
     forControlEvents:UIControlEventTouchUpInside];
    button.exclusiveTouch = YES;
    [view addSubview:button];
  }
  
  return view;
}

#pragma mark NYPLCatalogLaneCellDelegate

- (void)catalogLaneCell:(NYPLCatalogLaneCell *const)cell
     didSelectBookIndex:(NSUInteger const)bookIndex
{
  NYPLCatalogLane *const lane = self.catalogNavigationFeed.lanes[cell.laneIndex];
  NYPLBook *const book = lane.books[bookIndex];
  
  [[[NYPLBookDetailViewController alloc] initWithBook:book] presentFromViewController:self];
}

#pragma mark -

- (void)downloadFeed
{
  self.tableView.hidden = YES;
  self.activityIndicatorView.hidden = NO;
  [self.activityIndicatorView startAnimating];
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  [NYPLCatalogNavigationFeed
   withURL:self.URL
   handler:^(NYPLCatalogNavigationFeed *const navigationFeed) {
     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
       self.activityIndicatorView.hidden = YES;
       [self.activityIndicatorView stopAnimating];
       [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
       
       if(!navigationFeed) {
         self.reloadView.hidden = NO;
         return;
       }
       
       self.tableView.hidden = NO;
       self.catalogNavigationFeed = navigationFeed;
       [self.tableView reloadData];
       
       if(self.catalogNavigationFeed.searchTemplate) {
         self.navigationItem.rightBarButtonItem.enabled = YES;
       }
       
       [self downloadImages];
     }];
   }];
}

- (void)downloadImages
{
  if(self.indexOfNextLaneRequiringImageDownload >= self.catalogNavigationFeed.lanes.count) {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    return;
  }
  
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  NYPLCatalogLane *const lane =
    self.catalogNavigationFeed.lanes[self.indexOfNextLaneRequiringImageDownload];
  
  [[NYPLBookCoverRegistry sharedRegistry]
   thumbnailImagesForBooks:[NSSet setWithArray:lane.books]
   handler:^(NSDictionary *const bookIdentifiersToImages) {
     [self.bookIdentifiersToImages addEntriesFromDictionary:bookIdentifiersToImages];

     // We update this before reloading so that the delegate accurately knows which lanes already
     // have had their covers downloaded.
     ++self.indexOfNextLaneRequiringImageDownload;
     
     [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:
                                     (self.indexOfNextLaneRequiringImageDownload - 1)]
                   withRowAnimation:UITableViewRowAnimationNone];

     [self downloadImages];
   }];
}

- (void)didSelectCategory:(UIButton *const)button
{
  NYPLCatalogLane *const lane = self.catalogNavigationFeed.lanes[button.tag];
  
  switch(lane.subsectionLink.type) {
    case NYPLCatalogSubsectionLinkTypeAcquisition:
      [self.navigationController
       pushViewController:[[NYPLCatalogAcquisitionFeedViewController alloc]
                           initWithURL:lane.subsectionLink.URL
                           title:lane.title]
       animated:YES];
      break;
    case NYPLCatalogSubsectionLinkTypeNavigation:
      [self.navigationController
       pushViewController:[[NYPLCatalogNavigationFeedViewController alloc]
                           initWithURL:lane.subsectionLink.URL
                           title:lane.title]
       animated:YES];
      break;
  }
}

- (void)didSelectSearch
{
  [self.navigationController
   pushViewController:[[NYPLCatalogSearchViewController alloc]
                       initWithCategoryTitle:NSLocalizedString(@"Catalog", nil)
                       searchTemplate:self.catalogNavigationFeed.searchTemplate]
   animated:YES];
}

@end
