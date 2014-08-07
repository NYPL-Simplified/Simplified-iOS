#import "NYPLMyBooksDownloadCenter.h"
#import "NYPLReadium.h"

#import "NYPLReaderViewController.h"

@interface NYPLReaderViewController ()

@property (nonatomic) NSString *bookIdentifier;
@property (nonatomic) RDContainer *container;
@property (nonatomic) UIWebView *webView;

@end

@implementation NYPLReaderViewController

#pragma mark NSObject

- (instancetype)initWithBookIdentifier:(NSString *const)bookIdentifier
{
  self = [super init];
  if(!self) return nil;
  
  if(!bookIdentifier) {
    @throw NSInvalidArgumentException;
  }
  
  self.bookIdentifier = bookIdentifier;
  
  @try {
    self.container = [[RDContainer alloc] initWithPath:
                      [[[NYPLMyBooksDownloadCenter sharedDownloadCenter]
                        fileURLForBookIndentifier:bookIdentifier]
                       path]];
  } @catch (...) {
    [[[UIAlertView alloc]
      initWithTitle:NSLocalizedString(@"ReaderViewControllerCorruptTitle", nil)
      message:NSLocalizedString(@"ReaderViewControllerCorruptMessage", nil)
      delegate:nil
      cancelButtonTitle:nil
      otherButtonTitles:NSLocalizedString(@"OK", nil), nil]
     show];
  }

  self.hidesBottomBarWhenPushed = YES;
  
  return self;
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
  self.webView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                   UIViewAutoresizingFlexibleWidth);
  [self.view addSubview:self.webView];
}

@end
