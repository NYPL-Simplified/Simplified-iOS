#import "NYPLConfiguration.h"

#import "NYPLCatalogViewController.h"

@interface NYPLCatalogViewController ()

@property (nonatomic, retain) UIActivityIndicatorView *activityIndicatorView;

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

- (void)downloadFeed
{
  [self.activityIndicatorView startAnimating];
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  [[[NSURLSession sharedSession]
    dataTaskWithURL:[NYPLConfiguration mainFeedURL]
    completionHandler:^(NSData *const data, NSURLResponse *const response, NSError *const error) {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.activityIndicatorView stopAnimating];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if(!error) {
          [self loadFeedAndDisplay];
        } else {
          [[[UIAlertView alloc]
            initWithTitle:NSLocalizedString(@"CatalogFeedDownloadFailedTitle", nil)
            message:NSLocalizedString(@"CatalogFeedDownloadFailedMessage", nil)
            delegate:nil
            cancelButtonTitle:nil
            otherButtonTitles:@"OK", nil]
           show];
        }
      }];
    }]
   resume];
}

- (void)loadFeedAndDisplay
{
  
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  self.view.backgroundColor = [UIColor whiteColor];
  
  self.activityIndicatorView = [[UIActivityIndicatorView alloc]
                                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  self.activityIndicatorView.center = self.view.center;
  [self.view addSubview:self.activityIndicatorView];
  
  [self downloadFeed];
}

@end
