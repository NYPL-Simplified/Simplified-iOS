#import "NYPLConfiguration.h"

#import "NYPLSettingsAboutViewController.h"

@interface NYPLSettingsAboutViewController ()

@property (nonatomic) UIWebView *webView;

@end

@implementation NYPLSettingsAboutViewController

#pragma mark UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.title = NSLocalizedString(@"About", nil);
  
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
  
  self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
  self.webView.autoresizingMask = (UIViewAutoresizingFlexibleHeight
                                   | UIViewAutoresizingFlexibleWidth);
  self.webView.backgroundColor = [NYPLConfiguration backgroundColor];
  
  [self.webView loadRequest:
   [NSURLRequest requestWithURL:
    [[NSBundle mainBundle]
     URLForResource:@"about"
     withExtension:@"html"]]];
  
  [self.view addSubview:self.webView];
}

@end
