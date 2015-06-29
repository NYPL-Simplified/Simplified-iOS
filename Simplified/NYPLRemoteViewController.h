// This class is designed to provide a simple way to implement view controllers that must retreive
// some sort of network-available data before they can do anything. The idea is that an instance of
// |NYPLRemoteViewController| can be told to load the data present at some URL. While the data is
// downloading, it will display a progress indicator. Once the data has been retreived, the handler
// function provided will be called. That handler then returns a new view controller that is
// presented by the instance of |NYPLRemoteViewController|.

NS_ASSUME_NONNULL_BEGIN

@interface NYPLRemoteViewController : UIViewController

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

// |handler| is strongly retained.
- (instancetype)initWithURL:(NSURL *)URL
          completionHandler:(UIViewController *(^)(NSData *data))handler;

// This may be called more than once to reload the data accessible at the previously provided URL.
- (void)load;

@end

NS_ASSUME_NONNULL_END