// This class is designed to provide a simple way to implement view controllers that must retreive
// some sort of network-available data before they can do anything. The idea is that an instance of
// |NYPLRemoteViewController| can be told to load the data present at some URL. While the data is
// downloading, it will display a progress indicator. Once the data has been retreived, the handler
// function provided will be called. That handler then returns a new view controller that is
// presented by the instance of |NYPLRemoteViewController|.
//
// The current left and right bar buttons of the presented view controller, as well as the current
// title, will be displayed. Changes to said properties later on will not be shown, so be sure they
// are all set before the handler returns. (Changes to the items already /within/ the left and right
// sets of items will be correctly displayed, however.)

@interface NYPLRemoteViewController : UIViewController

// After changing this, you must call |load| to see the effect.
@property (atomic) NSURL *URL;

+ (id)new NS_UNAVAILABLE;
- (id)init NS_UNAVAILABLE;
- (id)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

// |handler| may not be nil. |handler| is strongly retained. |data| will never be nil as the handler
// is only called if the data was downloaded successfully. The handler may return nil to indicate
// that there is something wrong with the data.
- (instancetype)initWithURL:(NSURL *)URL
          completionHandler:(UIViewController *(^)(NYPLRemoteViewController *remoteViewController,
                                                   NSData *data,
                                                   NSURLResponse *response))handler;

// This may be called more than once to reload the data accessible at the previously provided URL.
- (void)load;

@end
