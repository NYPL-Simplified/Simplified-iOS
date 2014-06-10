#import "NYPLConfiguration.h"

#import "NYPLCatalogViewController.h"

typedef enum {
  FeedStateNotDownloaded,
  FeedStateDownloading,
  FeedStateLoaded
} FeedState;

@interface NYPLCatalogViewController ()

@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic) FeedState feedState;

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
  self.activityIndicatorView.center = self.view.center;
  [self.view addSubview:self.activityIndicatorView];
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

#pragma mark -

- (void)downloadFeed
{
  self.feedState = FeedStateDownloading;
  
  [self.activityIndicatorView startAnimating];
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  [[[NSURLSession sharedSession]
    dataTaskWithURL:[NYPLConfiguration mainFeedURL]
    completionHandler:^(__attribute__((unused)) NSData *data,
                        __attribute__((unused)) NSURLResponse *response,
                        NSError *const error) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.activityIndicatorView stopAnimating];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if(!error) {
          [self loadFeedAndDisplay];
        } else {
          self.feedState = FeedStateNotDownloaded;
          [[[UIAlertView alloc]
            initWithTitle:NSLocalizedString(@"CatalogFeedDownloadFailedTitle", nil)
            message:NSLocalizedString(@"CatalogFeedDownloadFailedMessage", nil)
            delegate:nil
            cancelButtonTitle:nil
            otherButtonTitles:NSLocalizedString(@"OK", nil), nil]
           show];
        }
      }];
    }]
   resume];
}

- (void)loadFeedAndDisplay
{
  
}

@end
