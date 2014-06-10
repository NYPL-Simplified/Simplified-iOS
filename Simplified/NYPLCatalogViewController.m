#import <SMXMLDocument/SMXMLDocument.h>

#import "NYPLOPDSEntry.h"
#import "NYPLOPDSFeed.h"

#import "NYPLCatalogViewController.h"

typedef enum {
  FeedStateNotDownloaded,
  FeedStateDownloading,
  FeedStateLoaded
} FeedState;

@interface NYPLCatalogViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic) NYPLOPDSFeed *feed;
@property (nonatomic) FeedState feedState;
@property (nonatomic) UITableView *tableView;

@end

@implementation NYPLCatalogViewController

#pragma mark NSObject

- (id)init
{
  self = [super init];
  if(!self) return nil;
  
  self.feedState = FeedStateNotDownloaded;
  
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
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.hidden = YES;
  [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(__attribute__((unused)) BOOL)animated
{
  switch(self.feedState) {
    case FeedStateNotDownloaded:
      [self downloadFeed];
      break;
    case FeedStateDownloading:
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
  static NSString *const reuseIdentifier = @"NYPLCatalogViewControllerCell";
  
  NSLog(@"Creating dummy cell for '%@'.",
        ((NYPLOPDSEntry *)self.feed.entries[[indexPath indexAtPosition:1]]).title);
  
  return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                reuseIdentifier:reuseIdentifier];
}

- (NSInteger)tableView:(__attribute__((unused)) UITableView *)tableView
 numberOfRowsInSection:(__attribute__((unused)) NSInteger)section
{
  return self.feed.entries.count;
}

#pragma mark -

- (void)downloadFeed
{
  self.feedState = FeedStateDownloading;
  
  [self.activityIndicatorView startAnimating];
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  [[[NSURLSession sharedSession]
    dataTaskWithURL:[NSURL URLWithString:NSLocalizedString(@"CatalogViewControllerFeedPath", nil)]
    completionHandler:^(NSData *data,
                        __attribute__((unused)) NSURLResponse *response,
                        NSError *const error) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.activityIndicatorView stopAnimating];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if(!error) {
          [self loadData:data];
        } else {
          self.feedState = FeedStateNotDownloaded;
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
    self.feedState = FeedStateNotDownloaded;
    [[[UIAlertView alloc]
      initWithTitle:NSLocalizedString(@"CatalogViewControllerBadDataTitle", nil)
      message:NSLocalizedString(@"CatalogViewControllerBadDataMessage", nil)
      delegate:nil
      cancelButtonTitle:nil
      otherButtonTitles:NSLocalizedString(@"OK", nil), nil]
     show];
    return;
  }
  
  self.feed = feed;
  self.feedState = FeedStateLoaded;
  [self.tableView reloadData];
  self.tableView.hidden = NO;
}

@end
