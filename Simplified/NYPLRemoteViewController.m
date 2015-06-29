#import "NYPLConfiguration.h"
#import "NYPLRemoteViewController.h"

@interface NYPLRemoteViewController () <NSURLConnectionDataDelegate>

@property (nonatomic) NSURLConnection *connection;
@property (nonatomic) NSMutableData *data;
@property (nonatomic, strong) UIViewController *(^handler)(NSData *data);
@property (nonatomic) NSURL *URL;

@end

@implementation NYPLRemoteViewController

- (instancetype)initWithURL:(NSURL *const)URL
          completionHandler:(UIViewController *(^ const)(NSData *data))handler
{
  self = [super init];
  if(!self) return nil;
  
  self.handler = handler;
  self.URL = URL;
  
  return self;
}

- (void)load
{
  // TODO
  NSLog(@"XXX: Loading!");
  
  [self.presentedViewController removeFromParentViewController];
  
  [self.connection cancel];
  
  NSURLRequest *const request = [NSURLRequest requestWithURL:self.URL
                                                 cachePolicy:NSURLRequestUseProtocolCachePolicy
                                             timeoutInterval:5.0];
  
  self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
  self.data = [NSMutableData data];
  
  [self.connection start];
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
}

#pragma mark NSURLConnectionDataDelegate

- (void)connection:(__attribute__((unused)) NSURLConnection *)connection
    didReceiveData:(NSData *const)data
{
  // TODO
  NSLog(@"XXX: Received data!");
  
  [self.data appendData:data];
}

- (void)connectionDidFinishLoading:(__attribute__((unused)) NSURLConnection *)connection
{
  // TODO
  NSLog(@"XXX: Done loading!");
  
  UIViewController *const viewController = self.handler(self.data);
  
  if(viewController) {
    [self addChildViewController:viewController];
    viewController.view.frame = self.view.bounds;
    [self.view addSubview:viewController.view];
    self.navigationItem.rightBarButtonItems = viewController.navigationItem.rightBarButtonItems;
    self.navigationItem.leftBarButtonItems = viewController.navigationItem.leftBarButtonItems;
    self.navigationItem.title = viewController.navigationItem.title;
    [viewController didMoveToParentViewController:self];
  } else {
    // TODO
    NSLog(@"XXX: Failed to get view controller!");
  }
  
  self.connection = nil;
  self.data = nil;
}

#pragma mark NSURLConnectionDelegate

- (void)connection:(__attribute__((unused)) NSURLConnection *)connection
  didFailWithError:(__attribute__((unused)) NSError *)error
{
  // TODO
  NSLog(@"XXX: An error occurred!");
  
  self.connection = nil;
  self.data = nil;
}

@end
