#import "NYPLConfiguration.h"

#import "NYPLSettingsEULAViewController.h"

@interface NYPLSettingsEULAViewController ()
@property (nonatomic) UIWebView *webView;
@end

@implementation NYPLSettingsEULAViewController

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.title = NSLocalizedString(@"EULA", nil);
  
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
  
  self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
  self.webView.autoresizingMask = (UIViewAutoresizingFlexibleHeight
                                   | UIViewAutoresizingFlexibleWidth);
  self.webView.backgroundColor = [NYPLConfiguration backgroundColor];
  [self.webView loadRequest:
   [NSURLRequest requestWithURL:
    [NSURL fileURLWithPath:
     [[NSBundle mainBundle]
      pathForResource:@"eula"
      ofType:@"html"]]]];
  [self.view addSubview:self.webView];
}

@end
