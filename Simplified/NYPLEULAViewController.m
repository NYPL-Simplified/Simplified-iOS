#import "NYPLConfiguration.h"

#import "NYPLEULAViewController.h"
#import "NYPLSettings.h"

@interface NYPLEULAViewController ()
@property (nonatomic, strong) void(^handler)(void);
@property (nonatomic) UIWebView *webView;
@end

static NSString * const onlineEULAPath = @"http://www.librarysimplified.org/EULA.html";
static NSString * const offlineEULAPathComponent = @"eula.html";

@implementation NYPLEULAViewController



#pragma mark NSObject

- (instancetype)initWithCompletionHandler:(void(^)(void))handler {
  
  {
    self = [super init];
    if(!self) return nil;
    
    if(!handler) {
      @throw NSInvalidArgumentException;
    }
    
    self.handler = handler;
    self.title = NSLocalizedString(@"EULA", nil);
    return self;
  }
}

#pragma mark UIViewController
- (void)viewDidLoad
{
  [super viewDidLoad];
  
  if ([[NYPLSettings sharedSettings] userAcceptedEULA]) {
    if (self.handler) self.handler();
    return;
  }
  
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
  
  UILabel *const label = [[UILabel alloc] init];
  label.frame = CGRectMake(self.view.frame.origin.x + 10, self.view.frame.origin.y + 30, CGRectGetWidth(label.frame), CGRectGetHeight(label.frame));
  [label setText:NSLocalizedString(@"EULA", nil)];
  [label setFont:[UIFont systemFontOfSize:21]];
  [label setTextColor:[NYPLConfiguration mainColor]];
  [label sizeToFit];
  [label setCenter: CGPointMake(self.view.center.x, label.center.y)];
  label.translatesAutoresizingMaskIntoConstraints = NO;
  
  [self.view addSubview:label];
  NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem: self.view attribute:NSLayoutAttributeCenterX multiplier:1.f constant:0];
  NSLayoutConstraint *verticalSpaceConstraint = [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem: self.view attribute:NSLayoutAttributeTop multiplier:1.f constant:30];
  
  [self.view addConstraint:centerXConstraint];
  [self.view addConstraint:verticalSpaceConstraint];
  self.view.translatesAutoresizingMaskIntoConstraints = NO;
  
  self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x, label.frame.origin.y + label.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - 100)];
  self.webView.autoresizingMask = (UIViewAutoresizingFlexibleHeight
                              | UIViewAutoresizingFlexibleWidth);
  self.webView.backgroundColor = [NYPLConfiguration backgroundColor];
  self.webView.delegate = self;
  [self.view addSubview:self.webView];
  [self loadWebView];
  
  UIButton *const acceptButton = [UIButton buttonWithType:UIButtonTypeSystem];
  acceptButton.titleLabel.font = [UIFont systemFontOfSize:21];
  NSString *const acceptTitle = NSLocalizedString(@"Accept", nil);
  acceptButton.translatesAutoresizingMaskIntoConstraints = NO;
  [acceptButton setTitle:acceptTitle forState:UIControlStateNormal];
  [acceptButton sizeToFit];
  acceptButton.frame = CGRectMake(self.view.frame.origin.x + 10, self.webView.frame.origin.y + self.webView.frame.size.height, CGRectGetWidth(acceptButton.frame), CGRectGetHeight(acceptButton.frame));
  [acceptButton addTarget:self
                   action:@selector(acceptedEULA)
         forControlEvents:UIControlEventTouchUpInside];
  acceptButton.exclusiveTouch = YES;
  [self.view addSubview:acceptButton];
  NSLayoutConstraint *bottomAcceptSpaceConstraint = [NSLayoutConstraint constraintWithItem:acceptButton attribute:NSLayoutAttributeBottomMargin relatedBy:NSLayoutRelationEqual toItem: self.webView attribute:NSLayoutAttributeBottomMargin multiplier:1.f constant:acceptButton.frame.size.height];
  
  NSLayoutConstraint *horizontalAcceptSpaceConstraint = [NSLayoutConstraint constraintWithItem:acceptButton attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem: self.view attribute:NSLayoutAttributeLeading multiplier:1.f constant:10];
  [self.view addConstraint:bottomAcceptSpaceConstraint];
  [self.view addConstraint:horizontalAcceptSpaceConstraint];
  
  UIButton *const rejectButton = [UIButton buttonWithType:UIButtonTypeSystem];
  rejectButton.titleLabel.font = [UIFont systemFontOfSize:21];
  NSString *const rejectTitle = NSLocalizedString(@"Reject", nil);
  rejectButton.translatesAutoresizingMaskIntoConstraints = NO;
  [rejectButton setTitle:rejectTitle forState:UIControlStateNormal];
  [rejectButton sizeToFit];
  rejectButton.frame = CGRectMake( (self.view.frame.origin.x + self.view.frame.size.width) - CGRectGetWidth(rejectButton.frame) - 10 , acceptButton.frame.origin.y, CGRectGetWidth(rejectButton.frame), CGRectGetHeight(rejectButton.frame));
  [rejectButton addTarget:self
                   action:@selector(rejectedEULA)
         forControlEvents:UIControlEventTouchUpInside];
  rejectButton.exclusiveTouch = YES;
  [self.view addSubview:rejectButton];
  NSLayoutConstraint *bottomRejectSpaceConstraint = [NSLayoutConstraint constraintWithItem:rejectButton attribute:NSLayoutAttributeBottomMargin relatedBy:NSLayoutRelationEqual toItem: self.webView attribute:NSLayoutAttributeBottomMargin multiplier:1.f constant:rejectButton.frame.size.height];
  
  NSLayoutConstraint *horizontalRejectSpaceConstraint = [NSLayoutConstraint constraintWithItem:rejectButton attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem: self.view attribute:NSLayoutAttributeTrailing multiplier:1.f constant:-10];
  [self.view addConstraint:bottomRejectSpaceConstraint];
  [self.view addConstraint:horizontalRejectSpaceConstraint];
}

- (void) acceptedEULA {
  [[NYPLSettings sharedSettings] setUserAcceptedEULA:YES];
  
  if (self.handler) self.handler();
}

- (void) rejectedEULA {
  [[NYPLSettings sharedSettings] setUserAcceptedEULA:NO];
  
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"NOTICE", nil)
                                                                           message:NSLocalizedString(@"EULAHaveToAgree", nil)
                                                                    preferredStyle:UIAlertControllerStyleAlert];
  
  UIAlertAction *exitAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                       style:UIAlertActionStyleDestructive
                                                     handler:nil];
  
  [alertController addAction:exitAction];
  [self presentViewController:alertController
                     animated:NO
                   completion:nil];
}

-(void) loadWebView {
  NSURL *url = [NSURL URLWithString:onlineEULAPath];
  NSURLRequest *const request = [NSURLRequest requestWithURL:url
                                                 cachePolicy:NSURLRequestUseProtocolCachePolicy
                                             timeoutInterval:5.0];
  
  [self.webView loadRequest:
   request];
}

-(void) loadWebViewFromBundle {
  [self.webView loadRequest:
   [NSURLRequest requestWithURL:
    [NSURL fileURLWithPath:
     [[NSBundle mainBundle]
      pathForResource:offlineEULAPathComponent
      ofType:nil]]]];
}

#pragma mark NSURLConnectionDelegate
- (void)webView:(__attribute__((unused)) UIWebView *)webView didFailLoadWithError:(__attribute__((unused)) NSError *)error {
  [self loadWebViewFromBundle];
}

-(BOOL)webView:(__attribute__((unused)) UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(__attribute__((unused)) UIWebViewNavigationType)navigationType {
  if ([[[request URL] absoluteString] isEqualToString:onlineEULAPath]) {
    return YES;
  }
  else if ([[[[request URL] absoluteString] lastPathComponent] isEqualToString:offlineEULAPathComponent]) {
    return YES;
  }

  return NO;
}

@end
