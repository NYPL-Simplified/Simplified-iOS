@import WebKit;

@class Account;

@interface NYPLSettingsEULAViewController : UIViewController <WKNavigationDelegate>

- (nonnull instancetype)initWithAccount:(nonnull Account *)account;
- (nonnull instancetype)initWithNYPLURL;

@end
