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
  
  self.title = @"All Books";
  
  return self;
}

- (void)loadNavigationFeed
{
  [self.activityIndicatorView startAnimating];
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  [[[NSURLSession sharedSession]
    dataTaskWithURL:[NYPLConfiguration mainFeedURL]
    completionHandler:^(NSData *const data, NSURLResponse *const response, NSError *const error) {
      NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.activityIndicatorView stopAnimating];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
      }];
    }]
   resume];
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  self.view.backgroundColor = [UIColor whiteColor];
  
  self.activityIndicatorView = [[UIActivityIndicatorView alloc]
                                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  self.activityIndicatorView.center = self.view.center;
  [self.view addSubview:self.activityIndicatorView];
  
  [self loadNavigationFeed];
}

@end
