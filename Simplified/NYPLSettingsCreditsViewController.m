#import "NYPLConfiguration.h"

#import "NYPLSettingsCreditsViewController.h"

@interface NYPLSettingsCreditsViewController ()

@property (nonatomic) UIWebView *webView;

@end

@implementation NYPLSettingsCreditsViewController

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.title = NSLocalizedString(@"CreditsAndAcknowledgements", nil);
  
  return self;
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
  self.webView.autoresizingMask = (UIViewAutoresizingFlexibleHeight
                                   | UIViewAutoresizingFlexibleWidth);
  self.webView.backgroundColor = [NYPLConfiguration backgroundColor];
  [self.webView loadRequest:
   [NSURLRequest requestWithURL:
    [NSURL fileURLWithPath:
     [[NSBundle mainBundle]
      pathForResource:@"credits"
      ofType:@"html"]]]];
  [self.view addSubview:self.webView];
}

@end
