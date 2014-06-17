#import <SMXMLDocument/SMXMLDocument.h>

#import "NYPLCatalogLaneCell.h"
#import "NYPLConfiguration.h"
#import "NYPLOPDSEntry.h"
#import "NYPLOPDSFeed.h"
#import "NYPLOPDSLink.h"

#import "NYPLCatalogViewController.h"

static CGFloat const rowHeight = 125.0;
static CGFloat const sectionBottomPadding = 5.0;
static CGFloat const sectionHeaderHeight = 30.0;

@interface NYPLCatalogViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic) NSMutableDictionary *imageDataDictionary;
@property (nonatomic) NYPLOPDSFeed *navigationFeed;
@property (nonatomic) NSUInteger nextRowToDownload;
@property (nonatomic) NSArray *sectionTitles;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSDictionary *urlToCategoryFeedDataDictionary;

@end

@implementation NYPLCatalogViewController

#pragma mark NSObject

- (id)init
{
  self = [super init];
  if(!self) return nil;
  
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

#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(__attribute__((unused)) UITableView *)tableView
         cellForRowAtIndexPath:(__attribute__((unused)) NSIndexPath *const)indexPath
{
  // TODO: This needs to be a "loading" cell.
  return [[UITableViewCell alloc] init];
}

- (NSInteger)tableView:(__attribute__((unused)) UITableView *)tableView
 numberOfRowsInSection:(__attribute__((unused)) NSInteger)section
{
  return 1;
}

- (NSInteger)numberOfSectionsInTableView:(__attribute__((unused)) UITableView *)tableView
{
  return self.sectionTitles.count;
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

- (CGFloat)tableView:(__attribute__((unused)) UITableView *)tableView
heightForFooterInSection:(__attribute__((unused)) NSInteger)section
{
  return sectionBottomPadding;
}

- (UIView *)tableView:(__attribute__((unused)) UITableView *)tableView
viewForHeaderInSection:(NSInteger const)section
{
  CGRect const frame = CGRectMake(0, 0, self.tableView.frame.size.width, sectionHeaderHeight);
  UIView *const view = [[UIView alloc] initWithFrame:frame];
  view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  
  {
    CGRect const frame = CGRectMake(5,
                                    5,
                                    self.tableView.frame.size.width,
                                    sectionHeaderHeight - 10);
    UILabel *const label = [[UILabel alloc] initWithFrame:frame];
    label.text = self.sectionTitles[section];
    [view addSubview:label];
  }
  
  view.backgroundColor = [UIColor whiteColor];
  
  return view;
}

- (UIView *)tableView:(__attribute__((unused)) UITableView *)tableView
viewForFooterInSection:(__attribute__((unused)) NSInteger)section
{
  CGRect const frame = CGRectMake(0, 0, self.tableView.frame.size.width, 5);
  UIView *const view = [[UIView alloc] initWithFrame:frame];
  
  view.backgroundColor = [UIColor whiteColor];
  
  return view;
}

#pragma mark -

- (void)downloadFeed
{
  self.tableView.hidden = YES;
  self.activityIndicatorView.hidden = NO;
  [self.activityIndicatorView startAnimating];
  
  [[[NSURLSession sharedSession]
    dataTaskWithURL:[NYPLConfiguration mainFeedURL]
    completionHandler:^(NSData *const data,
                        __attribute__((unused)) NSURLResponse *response,
                        NSError *const error) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.tableView.hidden = NO;
        self.activityIndicatorView.hidden = YES;
        [self.activityIndicatorView stopAnimating];
        if(!error) {
          [self loadFeedData:data];
        } else {
          [[[UIAlertView alloc]
            initWithTitle:NSLocalizedString(@"CatalogViewControllerFeedDownloadFailedTitle", nil)
            message:NSLocalizedString(@"CatalogViewControllerFeedDownloadFailedMessage", nil)
            delegate:nil
            cancelButtonTitle:nil
            otherButtonTitles:NSLocalizedString(@"OK", nil), nil]
           show];
        }
      }];
    }]
   resume];
}

- (void)loadFeedData:(NSData *)data
{
  SMXMLDocument *const document = [[SMXMLDocument alloc] initWithData:data error:NULL];
  self.navigationFeed = [[NYPLOPDSFeed alloc] initWithDocument:document];

  if(!self.navigationFeed) {
    [[[UIAlertView alloc]
      initWithTitle:NSLocalizedString(@"CatalogViewControllerBadDataTitle", nil)
      message:NSLocalizedString(@"CatalogViewControllerBadDataMessage", nil)
      delegate:nil
      cancelButtonTitle:nil
      otherButtonTitles:NSLocalizedString(@"OK", nil), nil]
     show];
    return;
  }
}

@end
