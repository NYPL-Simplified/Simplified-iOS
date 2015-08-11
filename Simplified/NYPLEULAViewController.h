@interface NYPLEULAViewController : UIViewController <UIWebViewDelegate>

- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

// |handler| may not be nil. |handler| is strongly retained.
- (instancetype)initWithCompletionHandler:(void(^)(void))handler;
@end
