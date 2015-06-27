#import "NYPLRemoteViewController.h"

@interface NYPLRemoteViewController ()

@property (nonatomic) NSURLConnection *connection;
@property (nonatomic, strong) UIViewController *(^handler)(NSData *);
@property (nonatomic) NSURL *URL;

@end

@implementation NYPLRemoteViewController

- (void)loadURL:(NSURL *const)URL
completionHandler:(UIViewController *(^ const)(NSData *data))handler
{
  self.URL = URL;
  self.handler = handler;
  
  [self load];
}

- (void)load
{
  NSURLRequest *const request = [NSURLRequest requestWithURL:self.URL
                                                 cachePolicy:NSURLRequestUseProtocolCachePolicy
                                             timeoutInterval:5.0];
  
  self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
  
  // TODO: Set up delegates.
  
  [self.connection start];
}

- (void)reload
{
  [self.connection cancel];
  self.connection = nil;
  
  [self.presentedViewController removeFromParentViewController];
  
  [self load];
}

@end
