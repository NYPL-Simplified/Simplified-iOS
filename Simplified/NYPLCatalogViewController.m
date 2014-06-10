#import <SMXMLDocument/SMXMLDocument.h>

#import "NYPLCatalogLaneCell.h"
#import "NYPLOPDSEntry.h"
#import "NYPLOPDSFeed.h"

#import "NYPLCatalogViewController.h"

typedef enum {
  FeedStateNotLoaded,
  FeedStateLoading,
  FeedStateLoaded
} FeedState;

@interface NYPLCatalogViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic) FeedState feedState;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSMutableArray *tableViewCells;

@end

@implementation NYPLCatalogViewController

#pragma mark NSObject

- (id)init
{
  self = [super init];
  if(!self) return nil;
  
  self.feedState = FeedStateNotLoaded;
  
  // Given that we will only ever have a small number of cells, and given that each cell will
  // require much effort and network activity to create, we keep all of them around and do not use
  // the usual reuse mechanism. All cells are created when the navigation feed is loaded, one
  // benefit of which is that we do not need to keep the feed itself in memory.
  self.tableViewCells = [NSMutableArray array];
  
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
  
  self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
  self.tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight);
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.hidden = YES;
  [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(__attribute__((unused)) BOOL)animated
{
  switch(self.feedState) {
    case FeedStateNotLoaded:
      [self downloadFeed];
      break;
    case FeedStateLoading:
      break;
    case FeedStateLoaded:
      break;
  }
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
         cellForRowAtIndexPath:(NSIndexPath *const)indexPath
{
  return self.tableViewCells[indexPath.row];
}

- (NSInteger)tableView:(__attribute__((unused)) UITableView *)tableView
 numberOfRowsInSection:(__attribute__((unused)) NSInteger)section
{
  return self.tableViewCells.count;
}

#pragma mark -

- (void)downloadFeed
{
  self.feedState = FeedStateLoading;
  
  [self.activityIndicatorView startAnimating];
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  [[[NSURLSession sharedSession]
    dataTaskWithURL:[NSURL URLWithString:NSLocalizedString(@"CatalogViewControllerFeedPath", nil)]
    completionHandler:^(NSData *const data,
                        __attribute__((unused)) NSURLResponse *response,
                        NSError *const error) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.activityIndicatorView stopAnimating];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if(!error) {
          [self loadData:data];
        } else {
          self.feedState = FeedStateNotLoaded;
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

- (void)loadData:(NSData *)data
{
  SMXMLDocument *const document = [[SMXMLDocument alloc] initWithData:data error:NULL];
  NYPLOPDSFeed *const feed = [[NYPLOPDSFeed alloc] initWithDocument:document];

  if(!feed) {
    self.feedState = FeedStateLoaded;
    [[[UIAlertView alloc]
      initWithTitle:NSLocalizedString(@"CatalogViewControllerBadDataTitle", nil)
      message:NSLocalizedString(@"CatalogViewControllerBadDataMessage", nil)
      delegate:nil
      cancelButtonTitle:nil
      otherButtonTitles:NSLocalizedString(@"OK", nil), nil]
     show];
    return;
  }
  
  for(NYPLOPDSEntry *const entry in feed.entries) {
    NYPLCatalogLaneCell *const cell = [[NYPLCatalogLaneCell alloc] initWithTitle:entry.title];
    if(!cell) {
      NSLog(@"NYPLCatalogViewController: Failed to create NYPLCatalogLaneCell.");
      continue;
    }
    [self.tableViewCells addObject:cell];
  }
  
  [self.tableView reloadData];
  self.tableView.hidden = NO;
  
  self.feedState = FeedStateLoaded;
}

@end
