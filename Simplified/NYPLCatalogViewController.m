#import <SMXMLDocument/SMXMLDocument.h>

#import "NYPLAsync.h"
#import "NYPLBookDetailView.h"
#import "NYPLBookDetailViewController.h"
#import "NYPLBookDetailViewiPad.h"
#import "NYPLCatalogCategoryViewController.h"
#import "NYPLBook.h"
#import "NYPLCatalogLane.h"
#import "NYPLCatalogLaneCell.h"
#import "NYPLCatalogRoot.h"
#import "NYPLConfiguration.h"
#import "NYPLOPDSEntry.h"
#import "NYPLOPDSFeed.h"
#import "NYPLOPDSLink.h"
#import "NYPLSession.h"

#import "NYPLCatalogViewController.h"

static CGFloat const rowHeight = 115.0;
static CGFloat const sectionHeaderHeight = 40.0;

@interface NYPLCatalogViewController ()
  <NYPLCatalogLaneCellDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic) NYPLBookDetailViewiPad *bookDetailViewiPad;
@property (nonatomic) NYPLCatalogRoot *catalogRoot;
@property (nonatomic) NSMutableDictionary *cachedCells;
@property (nonatomic) NSMutableDictionary *URLsToImageData;
@property (nonatomic) NSUInteger indexOfNextLaneRequiringImageDownload;
@property (nonatomic) UITableView *tableView;

@end

@implementation NYPLCatalogViewController

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.cachedCells = [NSMutableDictionary dictionary];
  self.URLsToImageData = [NSMutableDictionary dictionary];
  self.title = NSLocalizedString(@"CatalogViewControllerTitle", nil);
  
  return self;
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  self.view.backgroundColor = [UIColor whiteColor];
  
  self.activityIndicatorView = [[UIActivityIndicatorView alloc]
                                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  [self.view addSubview:self.activityIndicatorView];
  
  self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
  self.tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight);
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.sectionHeaderHeight = sectionHeaderHeight;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.allowsSelection = NO;
  self.tableView.hidden = YES;
  [self.view addSubview:self.tableView];
  
  [self downloadFeed];
}

- (void)viewWillLayoutSubviews
{
  self.activityIndicatorView.center = self.view.center;
  
  UIEdgeInsets const insets = UIEdgeInsetsMake(self.topLayoutGuide.length,
                                               0,
                                               self.bottomLayoutGuide.length,
                                               0);
  
  self.tableView.contentInset = insets;
  self.tableView.scrollIndicatorInsets = insets;
}

- (void)didReceiveMemoryWarning
{
  [self.cachedCells removeAllObjects];
}

#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(__attribute__((unused)) UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *const)indexPath
{
  UITableViewCell *const cachedCell = self.cachedCells[indexPath];
  if(cachedCell) {
    return cachedCell;
  }
  
  if(indexPath.section < (NSInteger) self.indexOfNextLaneRequiringImageDownload) {
    NYPLCatalogLaneCell *const cell =
      [[NYPLCatalogLaneCell alloc]
       initWithLaneIndex:indexPath.section
       books:((NYPLCatalogLane *) self.catalogRoot.lanes[indexPath.section]).books
       URLsToImageData:self.URLsToImageData];
    cell.delegate = self;
    self.cachedCells[indexPath] = cell;
    return cell;
  } else {
    // TODO: Add loading cell.
    return [[UITableViewCell alloc] init];
  }
}

- (NSInteger)tableView:(__attribute__((unused)) UITableView *)tableView
 numberOfRowsInSection:(__attribute__((unused)) NSInteger)section
{
  return 1;
}

- (NSInteger)numberOfSectionsInTableView:(__attribute__((unused)) UITableView *)tableView
{
  return self.catalogRoot.lanes.count;
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
  
  {
    UIButton *const button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    NSString *const title = ((NYPLCatalogLane *) self.catalogRoot.lanes[section]).title;
    [button setTitle:title forState:UIControlStateNormal];
    [button sizeToFit];
    button.frame = CGRectMake(5, 5, CGRectGetWidth(button.frame), CGRectGetHeight(button.frame));
    button.tag = section;
    [button addTarget:self
               action:@selector(didSelectButton:)
     forControlEvents:UIControlEventTouchUpInside];
    button.exclusiveTouch = YES;
    [view addSubview:button];
  }
  
  view.backgroundColor = [UIColor whiteColor];
  
  return view;
}

#pragma mark NYPLCatalogLaneCellDelegate

- (void)catalogLaneCell:(NYPLCatalogLaneCell *const)cell
     didSelectBookIndex:(NSUInteger const)bookIndex
{
  NYPLCatalogLane *const lane = self.catalogRoot.lanes[cell.laneIndex];
  NYPLBook *const book = lane.books[bookIndex];
  
  if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    [self.navigationController pushViewController:[[NYPLBookDetailViewController alloc]
                                                   initWithBook:book]
                                         animated:YES];
  } else {
    self.bookDetailViewiPad = [[NYPLBookDetailViewiPad alloc] initWithBook:book];
    
    [self.bookDetailViewiPad.closeButton addTarget:self
                                            action:@selector(didCloseDetailView)
                                  forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.bookDetailViewiPad];
    
    [self.bookDetailViewiPad animateDisplay];
  }
}

#pragma mark -

- (void)downloadFeed
{
  self.tableView.hidden = YES;
  self.activityIndicatorView.hidden = NO;
  [self.activityIndicatorView startAnimating];
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  [NYPLCatalogRoot
   withURL:[NYPLConfiguration mainFeedURL]
   handler:^(NYPLCatalogRoot *const root) {
     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
       self.activityIndicatorView.hidden = YES;
       [self.activityIndicatorView stopAnimating];
       [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
       
       if(!root) {
         [[[UIAlertView alloc]
           initWithTitle:NSLocalizedString(@"CatalogViewControllerFeedDownloadFailedTitle", nil)
           message:NSLocalizedString(@"CatalogViewControllerFeedDownloadFailedMessage", nil)
           delegate:nil
           cancelButtonTitle:nil
           otherButtonTitles:NSLocalizedString(@"OK", nil), nil]
          show];
         return;
       }
       
       self.tableView.hidden = NO;
       self.catalogRoot = root;
       [self.tableView reloadData];
       
       [self downloadImages];
     }];
   }];
}

- (void)downloadImages
{
  if(self.indexOfNextLaneRequiringImageDownload >= self.catalogRoot.lanes.count) {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    return;
  }
  
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  NYPLCatalogLane *const lane = self.catalogRoot.lanes[self.indexOfNextLaneRequiringImageDownload];
  
  [[NYPLSession sharedSession]
   withURLs:lane.imageURLs
   handler:^(NSDictionary *const URLToDataOrNull) {
     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
       [URLToDataOrNull enumerateKeysAndObjectsUsingBlock:^(id const key,
                                                            id const value,
                                                            __attribute__((unused)) BOOL *stop) {
         if(![value isKindOfClass:[NSNull class]]) {
           assert([key isKindOfClass:[NSURL class]]);
           assert([value isKindOfClass:[NSData class]]);
           [self.URLsToImageData setValue:value forKey:key];
         }
       }];
       
       [self.tableView reloadData];
       ++self.indexOfNextLaneRequiringImageDownload;
       [self downloadImages];
     }];
   }];
}

- (void)didSelectButton:(id)buttonObject
{
  assert([buttonObject isKindOfClass:[UIButton class]]);
  UIButton *const button = buttonObject;
  
  NYPLCatalogLane *const lane = self.catalogRoot.lanes[button.tag];
  
  // TODO: Show the correct controller based on the |lane.subsectionLink.type|.
  NYPLCatalogCategoryViewController *const viewController =
    [[NYPLCatalogCategoryViewController alloc]
     initWithURL:lane.subsectionLink.URL
     title:lane.title];
  
  [self.navigationController pushViewController:viewController animated:YES];
}

- (void)didCloseDetailView
{
  [self.bookDetailViewiPad animateRemoveFromSuperview];
  self.bookDetailViewiPad = nil;
}

@end
