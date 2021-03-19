@import WebKit;

@class Account;

@interface NYPLSettingsEULAViewController : UIViewController <WKNavigationDelegate>

- (instancetype)initWithAccount:(Account *)account;
- (instancetype)initWithNYPLURL;

@end
